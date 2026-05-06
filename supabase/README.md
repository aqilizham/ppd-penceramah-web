# Supabase Setup

Gunakan folder ini untuk menjadikan app GitHub Pages sebagai sistem sebenar dengan database, login, role dan upload dokumen.

## Langkah Ringkas

1. Cipta project di Supabase.
2. Buka SQL Editor dan jalankan `schema.sql`.
3. Buka Project Settings > API dan salin:
   - Project URL
   - anon public key
4. Masukkan nilai itu dalam `config.js`.
5. Push semula ke GitHub.
6. Daftar akaun sekolah melalui app.
7. Daftar akaun PPD, kemudian jadikan akaun itu role PPD melalui SQL:

```sql
update public.profiles
set role = 'ppd'
where email = 'email-pegawai-ppd@example.com';
```

## Nota Keselamatan

- `anon public key` boleh berada dalam frontend kerana kawalan sebenar dibuat melalui Row Level Security.
- Jangan letak `service_role key` dalam repo atau browser.
- Bucket `speaker-documents` adalah private.
- Role PPD tidak boleh didaftarkan sendiri dari app; ia mesti ditetapkan oleh admin database.
