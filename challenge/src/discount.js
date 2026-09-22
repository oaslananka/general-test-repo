export function applyDiscount(price, percent) {
  if (!Number.isFinite(price) || price < 0) {
    throw new TypeError("price must be a non-negative number");
  }
  if (!Number.isFinite(percent) || percent < 0 || percent > 100) {
    throw new TypeError("percent must be between 0 and 100");
  }

  // Fix: convert percent from 0..100 range to 0..1 range
  return price * (1 - percent / 100);
}
