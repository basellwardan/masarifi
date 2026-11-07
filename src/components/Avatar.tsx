import { useStore } from '../lib/store';

export function Avatar({ size = 46 }: { size?: number }) {
  const { name, photo } = useStore((s) => s.profile);
  const initial = name.trim().charAt(0).toUpperCase() || 'م';
  return (
    <div className="avatar" style={{ width: size, height: size, fontSize: size * 0.4 }}>
      {photo ? <img src={photo} alt="" /> : initial}
    </div>
  );
}
