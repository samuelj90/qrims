'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  Activity, 
  Users, 
  QrCode
} from 'lucide-react';

export default function Sidebar() {
  const pathname = usePathname();

  const links = [
    { href: '/', label: 'Dashboard', icon: Activity },
    { href: '/users', label: 'User Management', icon: Users },
    { href: '/products', label: 'Product QR Catalog', icon: QrCode },
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
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center font-bold text-slate-300">
            AD
          </div>
          <div>
            <p className="text-sm font-medium">Admin User</p>
            <p className="text-xs text-slate-500">admin@qrims.com</p>
          </div>
        </div>
      </div>
    </aside>
  );
}
