import React from 'react';
import { ShoppingBag, QrCode, Tag, Sparkles } from 'lucide-react';

async function getProducts() {
  const apiBaseUrl = process.env.API_URL || 'http://localhost:3000';
  const url = `${apiBaseUrl}/api/v1/products`;
  try {
    const res = await fetch(url, { cache: 'no-store' });
    if (!res.ok) {
      throw new Error(`Failed to fetch products: ${res.statusText}`);
    }
    return await res.json();
  } catch (error) {
    console.error('Error fetching products:', error);
    return [];
  }
}

export default async function ProductsPage() {
  const products = await getProducts();

  return (
    <main className="flex-1 overflow-y-auto bg-slate-950 p-8">
      <header className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-2xl font-bold text-slate-50">Product QR Catalog</h2>
          <p className="text-sm text-slate-400">Inventory control catalog and scan-testable QR code payloads</p>
        </div>
        <div className="flex items-center gap-3">
          <button className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-slate-100 rounded-lg text-sm font-semibold transition-colors shadow-lg shadow-indigo-950/20">
            <ShoppingBag size={16} />
            Create Product
          </button>
        </div>
      </header>

      {products.length === 0 ? (
        <div className="glass-card rounded-2xl p-12 text-center text-slate-500">
          <Tag className="mx-auto text-slate-600 mb-3" size={32} />
          No products found in the catalog.
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {products.map((product: any) => {
            // Format QR payload matching the offline decrypt syntax:
            // SKU:Name:Price:Discount:Tax:Compliment
            const qrPayload = `${product.sku}:${product.name}:${product.price}:${product.discount}:${product.tax}:${product.compliment || ''}`;
            const qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=150x150&color=ffffff&bgcolor=0f172a&data=${encodeURIComponent(qrPayload)}`;

            const formattedPrice = new Intl.NumberFormat('en-US', {
              style: 'currency',
              currency: 'USD',
            }).format(product.price);

            return (
              <div key={product.id} className="glass-card rounded-2xl p-6 flex flex-col justify-between hover:border-indigo-500/30 transition-all duration-300 group">
                <div>
                  <div className="flex justify-between items-start mb-4">
                    <div>
                      <span className="px-2 py-0.5 bg-slate-900 border border-slate-800 rounded font-mono text-xs text-indigo-400 font-semibold uppercase">
                        {product.sku}
                      </span>
                      <h3 className="font-semibold text-base text-slate-100 mt-2 line-clamp-1">{product.name}</h3>
                      <p className="text-xs text-slate-400 mt-1 line-clamp-2 min-h-[32px]">{product.compliment || 'No description available'}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-6 my-5 bg-slate-900/40 border border-slate-800/40 p-4 rounded-xl">
                    <div className="relative w-24 h-24 bg-slate-950 border border-slate-800 rounded-lg flex items-center justify-center overflow-hidden">
                      <img 
                        src={qrCodeUrl} 
                        alt={`QR code for ${product.sku}`} 
                        className="w-20 h-20 object-contain"
                      />
                    </div>
                    <div className="flex-1 space-y-1.5 text-xs text-slate-400">
                      <div className="flex justify-between">
                        <span>Price:</span>
                        <span className="font-semibold text-slate-200">{formattedPrice}</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Discount:</span>
                        <span className="font-semibold text-amber-400">
                          {product.discount > 0 ? `$${product.discount.toFixed(2)}` : 'None'}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span>Tax:</span>
                        <span className="font-semibold text-slate-300">${product.tax.toFixed(2)}</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="flex justify-between items-center text-xs text-slate-500 border-t border-slate-800/40 pt-4 mt-2">
                  <span className="flex items-center gap-1 text-[11px] text-emerald-400">
                    <Sparkles size={11} /> Scan to Test Checkout
                  </span>
                  <span className="flex items-center gap-1">
                    <QrCode size={12} className="text-slate-400" /> Payloads enabled
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </main>
  );
}
