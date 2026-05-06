# Custom Domain

URL GitHub Pages semasa:

`https://aqilizham.github.io/ppd-penceramah-web/`

Domain seperti `ppdpenceramah.com` boleh digunakan selepas domain itu dibeli dan DNS disambungkan kepada GitHub Pages.

## Rekod DNS Untuk Apex Domain

Untuk domain akar seperti `ppdpenceramah.com`, tambah rekod `A` berikut pada DNS provider:

```text
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153
```

Tambah juga rekod `AAAA` jika mahu sokongan IPv6:

```text
2606:50c0:8000::153
2606:50c0:8001::153
2606:50c0:8002::153
2606:50c0:8003::153
```

## Rekod DNS Untuk www

Untuk `www.ppdpenceramah.com`, tambah rekod `CNAME`:

```text
www -> aqilizham.github.io
```

## Fail CNAME Repo

Selepas DNS siap, tambah fail `CNAME` di root repo:

```text
ppdpenceramah.com
```

Kemudian aktifkan `Enforce HTTPS` di GitHub Pages.
