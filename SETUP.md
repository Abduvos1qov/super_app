# How to Use This Package with Claude Code

Bu fayl sizga shu paketni Claude Code'ga qanday ulash va loyihani birinchi marta ishga tushirishni ko'rsatadi.

## Step 1: Paketni o'z joyiga ko'chirish

Bu zip ichidagi `ride_hailing_monorepo/` papkasini siz Flutter loyihalaringiz saqlanadigan joyga ko'chiring:

```bash
# Masalan:
unzip ride_hailing_monorepo.zip -d ~/projects/
cd ~/projects/ride_hailing_monorepo
```

## Step 2: Git init qilish

```bash
git init
git add .
git commit -m "chore: scaffold monorepo structure with CLAUDE.md docs"
```

## Step 3: Claude Code'ni shu papkada ishga tushirish

```bash
claude
```

Claude Code ishga tushganda **avtomatik** quyidagilarni yuklaydi:

- `CLAUDE.md` (root)
- `ARCHITECTURE.md` — chunki root CLAUDE.md `@ARCHITECTURE.md` orqali havola qiladi
- `.claude/rules/dart-conventions.md`, `testing.md`, `ui-rules.md` — path-scoped

Boshqa CLAUDE.md fayllari (masalan, `packages/core/CLAUDE.md`) **kerak bo'lganda** yuklanadi — Claude o'sha papkadagi fayllarni o'qiganida.

## Step 4: Tekshirish

Claude Code ichida:

```
/memory
```

Bu buyruq hozir yuklanib turgan barcha CLAUDE.md va rule fayllarini ko'rsatadi. Shu ro'yxatda `CLAUDE.md`, `ARCHITECTURE.md`, va `.claude/rules/*.md` fayllarini ko'rishingiz kerak.

## Step 5: Plan mode'da birinchi buyruqni bering

`Shift+Tab` bilan Plan mode'ga o'ting va yozing:

```
Root pubspec.yaml, melos.yaml, analysis_options.yaml, .gitignore va 
README.md tayyor turibdi. CLAUDE.md va ARCHITECTURE.md ham joyida.

Endi monorepo skeletini qur:

1. packages/core — bosh paket. FareCalculator (pure function), 
   Money type (UZS uchun), Result<T, AppError> (sealed class), 
   AppError variantlari. Birinchi amaliy test fayl qo'sh.

2. packages/shared_models — birinchi model sifatida User (freezed 
   sealed union: Rider, Driver, Admin).

3. packages/shared_ui — AppTheme (light + dark), AppSpacing, 
   AppColors (semantic tokens), PrimaryButton golden test bilan.

4. packages/shared_services — ApiClient (dio) + AuthInterceptor skeleti.

5. apps/rider_app — flutter create bilan skelet, go_router 
   konfiguratsiyasi, ProviderScope, main.dart da shared paketlardan 
   bitta-bittadan foydalanish misoli.

Har bir paketda resolution: workspace bo'lsin. Har bir paketning 
pubspec.yaml'ini mos ravishda yozib ber.

Kodegen kerak bo'lgan joylarda (freezed, riverpod_generator) 
build.yaml ham tayyorla.

Oldin reja taqdim et, men tasdiqlayman, keyin yoz.
```

## Step 6: Rejani ko'rib chiqing va tasdiqlang

Claude sizga to'liq reja ko'rsatadi. Uni diqqat bilan o'qing:

- Qaysi paketlar yaratiladi?
- Qaysi fayllar yoziladi?
- Qaysi buyruqlar ishga tushadi?

Agar reja to'g'ri bo'lsa — `Accept plan` bosing. Agar biror narsa noto'g'ri bo'lsa, Claude'ga aytib tuzattiring.

## Step 7: Birinchi bootstrap

Reja bajarilgandan so'ng, terminal'da:

```bash
flutter pub get
melos bootstrap
melos run analyze
melos run test
```

Agar hammasi yashil bo'lsa — sizda ishlaydigan monorepo skelet tayyor.

## Keyingi qadamlar

1. Birinchi haqiqiy feature'ni qo'shing — masalan, rider_app'da onboarding ekrani
2. Har safar Claude xato qilsa — tuzating va **shu xatoni CLAUDE.md'ga qo'shing** (agar u har doim takrorlanishi mumkin bo'lsa)
3. Yangi paket qo'shsangiz — unga ham CLAUDE.md yozing
4. `CLAUDE.local.md` fayliga o'z shaxsiy sozlamalaringizni yozing (masalan: "Men emulator ishlatmayman, Pixel 7 real qurilmada test qilaman"). Bu fayl .gitignore'da, faqat sizda qoladi.

## Muammolar

### "Claude mening qoidalarimga rioya qilmayapti"

1. `/memory` buyrug'ini ishga tushiring — fayl yuklanayaptimi?
2. Agar yuklanmayotgan bo'lsa — Claude Code'ni qayta ishga tushiring
3. Agar yuklanayotgan bo'lsa — qoidangiz juda umumiy bo'lishi mumkin. Aniqroq qiling. "Kod to'g'ri formatda bo'lsin" emas, "2 space indent, trailing commas" deb yozing.

### "Kontekst oynasi tez to'lib qolyapti"

1. Uzoq CLAUDE.md fayllarni `@import` bilan ajrating
2. Path-scoped rules'dan foydalaning (`paths:` frontmatter)
3. `/compact` o'rniga `/clear` ishlating yangi vazifa boshlaganda

### "Yangi ishlab chiquvchi onboard qilmoqchiman"

`README.md` ni o'qib chiqsin, `CLAUDE.md` esa Claude uchun. Bu ikkisi ataylab ajratilgan.
