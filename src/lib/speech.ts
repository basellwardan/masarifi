import { Capacitor, type PluginListenerHandle } from '@capacitor/core';
import { SpeechRecognition } from '@capacitor-community/speech-recognition';
import type { Lang } from './currency';

export type SpeechError = 'unavailable' | 'denied' | 'failed';

export interface SpeechSession {
  stop: () => void;
}

interface Handlers {
  onPartial: (text: string) => void;
  onEnd: (finalText: string) => void;
  onError: (e: SpeechError) => void;
}

// Levantine Arabic is understood well by Google's ar-SA/ar-JO models; ar-JO is the
// closest dialect that is widely available as an offline pack.
const SILENCE_MS = 1800; // stop after this much quiet once words came in
const NO_SPEECH_MS = 7000; // give up if nothing is said
const MAX_LISTEN_MS = 20000;

const localeFor = (lang: Lang) => (lang === 'ar' ? 'ar-JO' : 'en-US');

export async function startListening(lang: Lang, h: Handlers): Promise<SpeechSession | null> {
  if (Capacitor.isNativePlatform()) return startNative(lang, h);
  return startWeb(lang, h);
}

async function startNative(lang: Lang, h: Handlers): Promise<SpeechSession | null> {
  try {
    const { available } = await SpeechRecognition.available();
    if (!available) {
      h.onError('unavailable');
      return null;
    }
    let perm = await SpeechRecognition.checkPermissions();
    if (perm.speechRecognition !== 'granted') perm = await SpeechRecognition.requestPermissions();
    if (perm.speechRecognition !== 'granted') {
      h.onError('denied');
      return null;
    }
    let last = '';
    let ended = false;
    const handles: PluginListenerHandle[] = [];
    let silence: ReturnType<typeof setTimeout> | undefined;
    const finish = () => {
      if (ended) return;
      ended = true;
      clearTimeout(silence);
      clearTimeout(cap);
      handles.forEach((x) => x.remove());
      h.onEnd(last);
    };
    const stop = () => {
      if (ended) return;
      SpeechRecognition.stop()
        .catch(() => undefined)
        .finally(() => setTimeout(finish, 350));
    };
    // iPhone keeps listening until told to stop, so stop by ourselves once the
    // user has been quiet for a moment (or never started talking).
    const armSilence = (ms: number) => {
      clearTimeout(silence);
      silence = setTimeout(stop, ms);
    };
    armSilence(NO_SPEECH_MS);
    const cap = setTimeout(stop, MAX_LISTEN_MS);
    handles.push(
      await SpeechRecognition.addListener('partialResults', (d: { matches?: string[] }) => {
        if (d.matches?.[0]) {
          last = d.matches[0];
          h.onPartial(last);
          armSilence(SILENCE_MS);
        }
      }),
    );
    handles.push(
      await SpeechRecognition.addListener('listeningState', (d: { status: 'started' | 'stopped' }) => {
        if (d.status === 'stopped') finish();
      }),
    );
    await SpeechRecognition.start({
      language: localeFor(lang),
      maxResults: 1,
      partialResults: true,
      popup: false,
    });
    return { stop };
  } catch {
    h.onError('failed');
    return null;
  }
}

// Browser fallback (used while previewing the UI in a desktop browser).
interface WebRec {
  lang: string;
  interimResults: boolean;
  continuous: boolean;
  onresult: (e: { results: ArrayLike<ArrayLike<{ transcript: string }>> }) => void;
  onerror: (e: { error: string }) => void;
  onend: () => void;
  start: () => void;
  stop: () => void;
}

function startWeb(lang: Lang, h: Handlers): SpeechSession | null {
  const w = window as unknown as { SpeechRecognition?: new () => WebRec; webkitSpeechRecognition?: new () => WebRec };
  const Ctor = w.SpeechRecognition ?? w.webkitSpeechRecognition;
  if (!Ctor) {
    h.onError('unavailable');
    return null;
  }
  const rec = new Ctor();
  rec.lang = localeFor(lang);
  rec.interimResults = true;
  rec.continuous = false;
  let last = '';
  rec.onresult = (e) => {
    last = Array.from(e.results)
      .map((r) => r[0].transcript)
      .join(' ');
    h.onPartial(last);
  };
  rec.onerror = (e) => h.onError(e.error === 'not-allowed' ? 'denied' : 'failed');
  rec.onend = () => h.onEnd(last);
  rec.start();
  return { stop: () => rec.stop() };
}
