/**
 * Escapes special regular expression characters in a string.
 * This is useful when creating a dynamic RegExp from user input or fields (like skill names)
 * that might contain characters like '+', '#', '.', etc.
 *
 * @param {string} string - The string to escape.
 * @returns {string} The escaped string safe for RegExp construction.
 */
const escapeRegExp = (string) => {
  if (typeof string !== 'string') return String(string ?? '');
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
};

module.exports = { escapeRegExp };
