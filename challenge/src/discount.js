export function applyDiscount(price, percent) {
  if (!Number.isFinite(price) || price < 0) {
    throw new TypeError("price must be a non-negative number");
  }
  if (!Number.isFinite(percent) || percent < 0 || percent > 100) {
    throw new TypeError("percent must be between 0 and 100");
  }

  // Intentional challenge bug: percent is 0..100, not 0..1.
  return price * (1 - percent);
}
