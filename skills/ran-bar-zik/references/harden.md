# Hardening — שכבות הגנה שכדאי שיהיו

לשימוש ב-`/ran-bar-zik harden`. זו לא רשימת באגים אלא רשימת **הגנות חסרות**.
לכל פריט: בדוק אם קיים בקוד/בקונפיג, ואם לא — הצע את הקטע הקונקרטי.

## Security headers (דיברות 3, 7)

```
Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-<random>'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), camera=(), microphone=()
```

- `unsafe-inline` / `unsafe-eval` ב-script-src מבטל את רוב הערך של ה-CSP — nonce או hash.
- Next.js/Nuxt/Vite: ה-CSP נכתב ב-middleware או בהגדרות ה-host, לא ב-meta tag.
- Trusted Types (`require-trusted-types-for 'script'`) חוסם DOM-XSS בשורש. שווה לדחוף.

## Cookies & session (דיבר 7)

```js
res.cookie('sid', token, {
  httpOnly: true, secure: true, sameSite: 'lax',
  maxAge: 1000 * 60 * 60 * 8, path: '/',
});
```
ודא גם: rotation של session ב-login, invalidation ב-logout, ו-CSRF token או
`SameSite=strict` לפעולות משנות-מצב.

## Rate limiting (דיבר 10)

חובה על: login, הרשמה, שחזור סיסמה, טפסי יצירת קשר, endpoints של חיפוש/ייצוא,
וכל endpoint שמייצר עלות (מייל, SMS, LLM). ללא זה — enumeration, credential
stuffing וחשבון ענן שמתפוצץ.

## Auth (דיברות 1, 4)

- הרשאה נבדקת ב-middleware **וגם** ברמת האובייקט. route-level לבד = IDOR.
- `role` נלקח מה-session/טוקן, לעולם לא מגוף הבקשה.
- deny-by-default: endpoint חדש הוא סגור עד שמסמנים אותו כפומבי.

## CI (דיבר 8)

- `npm audit --audit-level=high` / `pnpm audit` כשלב חוסם.
- Dependabot/Renovate + lockfile מקומיט.
- סורק סודות (gitleaks/trufflehog) על כל PR — לא רק על main.
- SRI לכל `<script src>` חיצוני, או self-hosting של הספרייה.

## Logs & errors (דיבר 10)

- שגיאה גנרית ללקוח + מזהה בקשה; ה-stack נשאר בלוג הפנימי.
- redaction list ללוגר: `password`, `token`, `authorization`, `cookie`, `id_number`, `ת"ז`.
- אל תלוג `req.body` שלם.

## מידע אישי ישראלי (דיבר 10)

ת"ז, מידע רפואי, פרטי ילדים ופרטי קשר — מוסדרים בחוק הגנת הפרטיות ובתקנות אבטחת
מידע. דרוש: מזעור איסוף, הצפנה ב-rest, בקרת גישה מתועדת, מדיניות מחיקה, ותיעוד
מאגר. חשיפה = סיכון משפטי, לא רק באג.
