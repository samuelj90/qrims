'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { ShoppingBag, X, Check, Loader2 } from 'lucide-react';

export default function AddProductModal() {
  const [isOpen, setIsOpen] = useState(false);
  const [sku, setSku] = useState('');
  const [name, setName] = useState('');
  const [price, setPrice] = useState('');
  const [discount, setDiscount] = useState('0');
  const [tax, setTax] = useState('5.0');
  const [compliment, setCompliment] = useState('');
  
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!sku || !name || !price) {
      setError('Please fill in all required fields (SKU, Name, Price).');
      return;
    }
    
    setIsSubmitting(true);
    setError(null);

    // Compute api endpoint relative to the current browser hostname
    const apiBaseUrl = `${window.location.protocol}//${window.location.hostname}:3000`;
    
    try {
      const res = await fetch(`${apiBaseUrl}/api/v1/products`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          sku,
          name,
          price: parseFloat(price),
          discount: parseFloat(discount) || 0.0,
          tax: parseFloat(tax) || 0.0,
          compliment: compliment || undefined,
        }),
      });

      if (!res.ok) {
        const errorData = await res.json().catch(() => ({}));
        throw new Error(errorData.message || `Failed to create product (${res.status})`);
      }

      // Reset and close
      setIsOpen(false);
      setSku('');
      setName('');
      setPrice('');
      setDiscount('0');
      setTax('5.0');
      setCompliment('');
      router.refresh();
    } catch (err: any) {
      setError(err.message || 'Something went wrong.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <>
      <button 
        onClick={() => setIsOpen(true)}
        className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-slate-100 rounded-lg text-sm font-semibold transition-colors shadow-lg shadow-indigo-950/20"
      >
        <ShoppingBag size={16} />
        Create Product
      </button>

      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/80 backdrop-blur-sm p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-md p-6 relative shadow-2xl">
            <button 
              onClick={() => setIsOpen(false)}
              className="absolute top-4 right-4 text-slate-400 hover:text-slate-200 transition-colors"
            >
              <X size={20} />
            </button>

            <h3 className="text-lg font-bold text-slate-100 mb-2 flex items-center gap-2">
              <ShoppingBag className="text-indigo-400" size={20} />
              Add Product to Catalog
            </h3>
            <p className="text-xs text-slate-400 mb-4">Define a new inventory SKU and its QR metadata parameters.</p>

            {error && (
              <div className="bg-red-950/50 border border-red-900/50 text-red-400 p-3 rounded-lg text-xs mb-4">
                {error}
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">
                  SKU Code *
                </label>
                <input 
                  type="text" 
                  required
                  placeholder="e.g. PROD-011"
                  value={sku}
                  onChange={(e) => setSku(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-indigo-500 transition-colors"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">
                  Product Name *
                </label>
                <input 
                  type="text" 
                  required
                  placeholder="e.g. Mechanical Keyboard"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-indigo-500 transition-colors"
                />
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Price ($) *
                  </label>
                  <input 
                    type="number" 
                    step="0.01"
                    required
                    placeholder="29.99"
                    value={price}
                    onChange={(e) => setPrice(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-indigo-500 transition-colors"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Discount ($)
                  </label>
                  <input 
                    type="number" 
                    step="0.01"
                    placeholder="0"
                    value={discount}
                    onChange={(e) => setDiscount(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-indigo-500 transition-colors"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Tax ($)
                  </label>
                  <input 
                    type="number" 
                    step="0.01"
                    placeholder="5.00"
                    value={tax}
                    onChange={(e) => setTax(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-indigo-500 transition-colors"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">
                  Compliment / Description
                </label>
                <textarea 
                  rows={2}
                  placeholder="e.g. Ergonomic design, blue switches..."
                  value={compliment}
                  onChange={(e) => setCompliment(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-indigo-500 transition-colors resize-none"
                />
              </div>

              <div className="flex gap-3 pt-2">
                <button 
                  type="button"
                  onClick={() => setIsOpen(false)}
                  className="flex-1 bg-slate-800 hover:bg-slate-700 text-slate-200 text-sm font-semibold py-2 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  disabled={isSubmitting}
                  className="flex-1 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-850 text-slate-100 text-sm font-semibold py-2 rounded-lg transition-colors flex items-center justify-center gap-2"
                >
                  {isSubmitting ? (
                    <>
                      <Loader2 className="animate-spin" size={16} />
                      Saving...
                    </>
                  ) : (
                    <>
                      <Check size={16} />
                      Save Product
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}
