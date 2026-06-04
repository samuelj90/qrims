import React from 'react';
import { 
  TrendingUp, 
  Smartphone, 
  Database, 
  QrCode, 
  ShieldAlert, 
  Activity, 
  Users, 
  ShoppingCart,
  Zap
} from 'lucide-react';

export default function DashboardPage() {
  return (
    <div className="flex-1 flex flex-col md:flex-row h-screen overflow-hidden">
      {/* Sidebar Navigation */}
      <aside className="w-full md:w-64 bg-slate-900 border-r border-slate-800 p-6 flex flex-col justify-between">
        <div>
          <div className="flex items-center gap-3 mb-8">
            <div className="p-2.5 bg-indigo-600 rounded-lg text-white font-bold">
              QR
            </div>
            <div>
              <h1 className="font-semibold text-lg leading-tight">QRIMS Platform</h1>
              <span className="text-xs text-slate-500">v2.0 Redesign</span>
            </div>
          </div>
          
          <nav className="space-y-1.5">
            <a href="#" className="flex items-center gap-3 px-4 py-2.5 rounded-lg bg-indigo-950 text-indigo-200 border border-indigo-900/50 text-sm font-medium">
              <Activity size={18} />
              Dashboard
            </a>
            <a href="#" className="flex items-center gap-3 px-4 py-2.5 rounded-lg hover:bg-slate-800 text-slate-400 hover:text-slate-100 text-sm font-medium transition-colors">
              <Users size={18} />
              User Management
            </a>
            <a href="#" className="flex items-center gap-3 px-4 py-2.5 rounded-lg hover:bg-slate-800 text-slate-400 hover:text-slate-100 text-sm font-medium transition-colors">
              <QrCode size={18} />
              Product QR Catalog
            </a>
            <a href="#" className="flex items-center gap-3 px-4 py-2.5 rounded-lg hover:bg-slate-800 text-slate-400 hover:text-slate-100 text-sm font-medium transition-colors">
              <ShieldAlert size={18} />
              Security Audits
            </a>
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

      {/* Main Content Area */}
      <main className="flex-1 overflow-y-auto bg-slate-950 p-8">
        <header className="flex items-center justify-between mb-8">
          <div>
            <h2 className="text-2xl font-bold text-slate-50">Operations Console</h2>
            <p className="text-sm text-slate-400">Real-time status of the QR Inventory Ecosystem</p>
          </div>
          <div className="flex items-center gap-3">
            <span className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-950 text-emerald-400 border border-emerald-900 rounded-full text-xs font-medium">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
              All Systems Operational
            </span>
          </div>
        </header>

        {/* Bento Grid Widget System */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 auto-rows-[160px]">
          
          {/* Card 1: Revenue & Checkout Volumes (2x2) */}
          <div className="md:col-span-2 md:row-span-2 glass-card rounded-2xl p-6 flex flex-col justify-between">
            <div className="flex justify-between items-start">
              <div>
                <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">Ecosystem Checkout Flow</span>
                <h3 className="text-3xl font-bold mt-1 text-slate-100">$24,950.50</h3>
              </div>
              <span className="p-2 bg-indigo-950/50 text-indigo-400 border border-indigo-900/30 rounded-lg">
                <TrendingUp size={20} />
              </span>
            </div>
            
            {/* Visual Sparkline representation using CSS */}
            <div className="h-24 w-full flex items-end gap-2 mt-4">
              {[40, 55, 30, 85, 45, 60, 95, 75, 90, 65, 100].map((height, i) => (
                <div key={i} className="flex-1 bg-gradient-to-t from-indigo-600 to-cyan-400 rounded-t" style={{ height: `${height}%` }} />
              ))}
            </div>
            
            <div className="flex justify-between items-center text-xs text-slate-400 border-t border-slate-800/40 pt-4 mt-2">
              <span className="flex items-center gap-1 text-emerald-400">
                <Zap size={12} /> +12.4% vs last week
              </span>
              <span>11 active cashiers</span>
            </div>
          </div>

          {/* Card 2: Mobile Devices & Sync Queue (1x2) */}
          <div className="md:col-span-1 md:row-span-2 glass-card rounded-2xl p-6 flex flex-col justify-between">
            <div>
              <div className="flex justify-between items-start">
                <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">Device Syncs</span>
                <span className="p-2 bg-cyan-950/50 text-cyan-400 border border-cyan-900/30 rounded-lg">
                  <Smartphone size={20} />
                </span>
              </div>
              <h4 className="text-xl font-bold mt-2">Mobile Terminals</h4>
              <p className="text-xs text-slate-400 mt-1">Status of API Gateway clients</p>
            </div>

            <div className="space-y-4 my-4">
              <div className="flex justify-between items-center text-sm">
                <span className="text-slate-400">Active Terminals</span>
                <span className="font-semibold text-slate-200">14 Online</span>
              </div>
              <div className="flex justify-between items-center text-sm">
                <span className="text-slate-400">Sync Queue size</span>
                <span className="px-2 py-0.5 bg-yellow-950 text-yellow-400 border border-yellow-900 text-xs rounded font-medium">0 Pending</span>
              </div>
              <div className="w-full bg-slate-900 rounded-full h-1.5">
                <div className="bg-cyan-500 h-1.5 rounded-full" style={{ width: '100%' }}></div>
              </div>
            </div>

            <div className="text-xs text-slate-500">
              Migration: Sockets deprecated. All syncs routed via HTTPS REST.
            </div>
          </div>

          {/* Card 3: Product Catalog Status (1x1) */}
          <div className="glass-card rounded-2xl p-6 flex flex-col justify-between">
            <div className="flex justify-between items-center">
              <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">Catalog</span>
              <ShoppingCart size={16} className="text-emerald-400" />
            </div>
            <div>
              <p className="text-2xl font-bold">1,842</p>
              <p className="text-xs text-slate-400">Total active SKUs</p>
            </div>
            <div className="text-[11px] text-emerald-400 flex items-center gap-1">
              <span>●</span> 4 new products added today
            </div>
          </div>

          {/* Card 4: QR Security (1x1) */}
          <div className="glass-card rounded-2xl p-6 flex flex-col justify-between">
            <div className="flex justify-between items-center">
              <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">QR Encryption</span>
              <QrCode size={16} className="text-amber-400" />
            </div>
            <div>
              <p className="text-sm font-semibold text-slate-200">PBKDF2 + AES-GCM</p>
              <p className="text-xs text-slate-400">State: Enforced</p>
            </div>
            <div className="text-[11px] text-amber-500">
              Legacy SHA1PRNG revoked
            </div>
          </div>

          {/* Card 5: Real-time Audit Feed (2x2) */}
          <div className="md:col-span-2 md:row-span-2 glass-card rounded-2xl p-6 flex flex-col justify-between">
            <div>
              <div className="flex justify-between items-start mb-4">
                <div>
                  <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">Ecosystem Auditing</span>
                  <h4 className="text-lg font-bold text-slate-100">Live Security & Operations Logs</h4>
                </div>
                <span className="px-2.5 py-1 bg-red-950/60 text-red-400 border border-red-900/50 rounded-full text-xs font-medium">
                  RBAC Active
                </span>
              </div>
              
              <div className="space-y-3.5 max-h-[190px] overflow-y-auto pr-1 text-xs">
                <div className="flex justify-between items-start border-b border-slate-900 pb-2.5">
                  <div>
                    <span className="text-slate-400 font-medium">[SYSTEM]</span>
                    <p className="text-slate-300 mt-0.5">Flush Sync Queue for client terminal (Device ID: #F41A)</p>
                  </div>
                  <span className="text-slate-500">00:08</span>
                </div>
                <div className="flex justify-between items-start border-b border-slate-900 pb-2.5">
                  <div>
                    <span className="text-amber-400 font-medium">[SECURITY]</span>
                    <p className="text-slate-300 mt-0.5">Password changed for user ID: customer_3910</p>
                  </div>
                  <span className="text-slate-500">23:45</span>
                </div>
                <div className="flex justify-between items-start border-b border-slate-900 pb-2.5">
                  <div>
                    <span className="text-indigo-400 font-medium">[ADMIN]</span>
                    <p className="text-slate-300 mt-0.5">Role promotion: staff_danielle granted ROLE_STAFF</p>
                  </div>
                  <span className="text-slate-500">22:04</span>
                </div>
              </div>
            </div>
            
            <div className="text-xs text-indigo-400 hover:underline cursor-pointer pt-2">
              View all system audit logs →
            </div>
          </div>

          {/* Card 6: Database & API Health (1x1) */}
          <div className="glass-card rounded-2xl p-6 flex flex-col justify-between">
            <div className="flex justify-between items-center">
              <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">Health</span>
              <Database size={16} className="text-blue-400" />
            </div>
            <div>
              <p className="text-2xl font-bold">99.98%</p>
              <p className="text-xs text-slate-400">Postgres / Redis uptime</p>
            </div>
            <div className="text-[11px] text-blue-400 flex items-center gap-1">
              <span>●</span> Latency: 12ms avg
            </div>
          </div>

          {/* Card 7: User Roles (1x1) */}
          <div className="glass-card rounded-2xl p-6 flex flex-col justify-between">
            <div className="flex justify-between items-center">
              <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">Access Controls</span>
              <Users size={16} className="text-indigo-400" />
            </div>
            <div>
              <p className="text-2xl font-bold">186</p>
              <p className="text-xs text-slate-400">Registered users</p>
            </div>
            <div className="text-[11px] text-slate-500 flex justify-between">
              <span>3 Admins</span>
              <span>24 Staff</span>
            </div>
          </div>

        </div>
      </main>
    </div>
  );
}
