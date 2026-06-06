import React from 'react';
import { Users, UserCheck, ShieldAlert, Key } from 'lucide-react';

async function getUsers() {
  const apiBaseUrl = process.env.API_URL || 'http://localhost:3000';
  const url = `${apiBaseUrl}/api/v1/users`;
  try {
    const res = await fetch(url, { cache: 'no-store' });
    if (!res.ok) {
      throw new Error(`Failed to fetch users: ${res.statusText}`);
    }
    return await res.json();
  } catch (error) {
    console.error('Error fetching users:', error);
    return [];
  }
}

export default async function UsersPage() {
  const users = await getUsers();

  return (
    <main className="flex-1 overflow-y-auto bg-slate-950 p-8">
      <header className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-2xl font-bold text-slate-55">User Management</h2>
          <p className="text-sm text-slate-400">Administer system users, credentials, and access control permissions</p>
        </div>
        <div className="flex items-center gap-3">
          <button className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-slate-100 rounded-lg text-sm font-semibold transition-colors shadow-lg shadow-indigo-950/20">
            <Users size={16} />
            Add New User
          </button>
        </div>
      </header>

      <div className="glass-card rounded-2xl p-6">
        <div className="flex justify-between items-center mb-6">
          <h3 className="font-semibold text-lg text-slate-100 flex items-center gap-2">
            <UserCheck className="text-indigo-400" size={20} />
            Registered Accounts
          </h3>
          <span className="px-2.5 py-1 bg-slate-900 border border-slate-800 rounded-full text-xs font-semibold text-slate-400">
            {users.length} Total Users
          </span>
        </div>

        {users.length === 0 ? (
          <div className="text-slate-500 text-center py-12">
            <ShieldAlert className="mx-auto text-slate-600 mb-3" size={32} />
            No user accounts found in the database.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-800 text-slate-400 text-xs font-semibold uppercase tracking-wider">
                  <th className="py-4 px-4">Username</th>
                  <th className="py-4 px-4">User ID</th>
                  <th className="py-4 px-4">Role</th>
                  <th className="py-4 px-4">Created Date</th>
                  <th className="py-4 px-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/50 text-sm text-slate-300">
                {users.map((user: any) => (
                  <tr key={user.id} className="hover:bg-slate-900/40 transition-colors">
                    <td className="py-4 px-4 font-semibold text-slate-200">{user.username}</td>
                    <td className="py-4 px-4 font-mono text-xs text-slate-500">{user.id}</td>
                    <td className="py-4 px-4">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${
                        user.role === 'ADMIN' 
                          ? 'bg-red-950 text-red-400 border border-red-900/50' 
                          : user.role === 'STAFF'
                          ? 'bg-amber-950 text-amber-400 border border-amber-900/50'
                          : 'bg-emerald-950 text-emerald-400 border border-emerald-900/50'
                      }`}>
                        {user.role}
                      </span>
                    </td>
                    <td className="py-4 px-4 text-slate-400">
                      {new Date(user.createdAt).toLocaleDateString([], { 
                        year: 'numeric', 
                        month: 'short', 
                        day: 'numeric' 
                      })}
                    </td>
                    <td className="py-4 px-4 text-right">
                      <button className="text-xs text-indigo-400 hover:text-indigo-300 hover:underline flex items-center gap-1 ml-auto">
                        <Key size={12} />
                        Reset Password
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </main>
  );
}
