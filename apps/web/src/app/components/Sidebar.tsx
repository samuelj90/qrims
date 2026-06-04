'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  Activity, 
  Users, 
  QrCode,
  Settings
} from 'lucide-react';

export default function Sidebar() {
  const pathname = usePathname();
  const [profilePic, setProfilePic] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (typeof window !== 'undefined') {
      setProfilePic(localStorage.getItem('web_profile_picture_path'));
    }
  }, []);

  const links = [
    { href: '/', label: 'Dashboard', icon: Activity },
    { href: '/users', label: 'User Management', icon: Users },
    { href: '/products', label: 'Product QR Catalog', icon: QrCode },
    { href: '/settings', label: 'Settings', icon: Settings },
  ];

  return (
    <aside className="w-full md:w-64 bg-slate-900 border-r border-slate-800 p-6 flex flex-col justify-between h-screen shrink-0">
      <div>
        <div className="flex items-center gap-3 mb-8">
          {/* Logo sourced from Next.js public directory */}
          <img src="/logo.svg" alt="QRIMS Logo" className="w-10 h-10 object-contain" />
          <div>
            <h1 className="font-semibold text-lg leading-tight">QRIMS Platform</h1>
          </div>
        </div>
        
        <nav className="space-y-1.5">
          {links.map((link) => {
            const Icon = link.icon;
            const isActive = pathname === link.href;
            return (
              <Link
                key={link.href}
                href={link.href}
                className={`flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm font-medium border transition-colors ${
                  isActive 
                    ? 'bg-indigo-950 text-indigo-200 border-indigo-900/50' 
                    : 'hover:bg-slate-800 text-slate-400 hover:text-slate-100 border-transparent'
                }`}
              >
                <Icon size={18} />
                {link.label}
              </Link>
            );
          })}
        </nav>
      </div>

      <div className="border-t border-slate-800 pt-6">
        <Link href="/settings" className="flex items-center gap-3 hover:opacity-85 transition-opacity">
          {profilePic ? (
            <img src={profilePic} alt="User Profile" className="w-10 h-10 rounded-full object-cover border border-slate-700" />
          ) : (
            <div className="w-10 h-10 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center font-bold text-slate-300">
              OP
            </div>
          )}
          <div>
            <p className="text-sm font-medium text-slate-200">System Operator</p>
            <p className="text-xs text-slate-500">operator@qrims.com</p>
          </div>
        </Link>
      </div>
    </aside>
  );
}
