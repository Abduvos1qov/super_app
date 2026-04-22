# How to Use This Monorepo with Claude Code

Bu fayl sizga super-app platform monorepo'sini Claude Code bilan qanday ishlatishni va birinchi marta ishga tushirishni ko'rsatadi.

## Step 1: Repository'ni klonlash

```bash
git clone <your-repo-url> super_app
cd super_app
```

## Step 2: Branch va commit tayyorlash

```bash
git checkout -b feat/bootstrap/local-setup
```

## Step 3: Claude Code'ni shu papkada ishga tushirish

```bash
claude
```

Claude Code ishga tushganda **avtomatik** quyidagilarni yuklaydi:

- `CLAUDE.md` (root) — super-app platform qoidalari
- `ARCHITECTURE.md` — chunki root `CLAUDE.md` `@ARCHITECTURE.md` orqali havola qiladi
- `.claude/rules/dart-conventions.md`, `testing.md`, `ui-rules.md` — path-scoped rules

Boshqa `CLAUDE.md` fayllari (masalan, `packages/mini_app_sdk/CLAUDE.md`, `packages/shared_ui/CLAUDE.md`) **kerak bo'lganda** yuklanadi — Claude o'sha papkadagi fayllar bilan ishlaganida.

## Step 4: Kontekst to'g'ri yuklanganini tekshirish

Claude Code ichida:

```
/memory
```

Bu buyruq hozir yuklanib turgan barcha `CLAUDE.md` va rule fayllarini ko'rsatadi. Ro'yxatda `CLAUDE.md`, `ARCHITECTURE.md`, va `.claude/rules/*.md` fayllari bo'lishi kerak.

## Step 5: Birinchi bootstrap

Terminalda:

```bash
# 1. Workspaces bo'yicha barcha bog'liqliklarni yechadi
flutter pub get

# 2. Melos hooklari, codegen, init'lar
melos bootstrap

# 3. Tekshirish
melos run analyze
melos run test
```

Agar hammasi yashil bo'lsa — sizda ishlaydigan super-app platform skeleti tayyor.

## Step 6: Shell'ni ishga tushirish

```bash
cd apps/super_app
flutter run
```

Demo mini-app ko'rinishi kerak — bu sizga platformaning uchidan uchiga ishlayotganini tasdiqlaydi.

## Step 7: Birinchi vazifa — yangi mini-app qo'shish

Plan mode'ga `Shift+Tab` bilan o'ting va yozing:

```
Men `packages/mini_apps/demo_mini_app/` ni reference sifatida ko'rib, 
yangi `packages/mini_apps/<your_mini_app>/` yaratmoqchiman.

Talablar:
- Faqat `core`, `shared_models`, `shared_ui`, `mini_app_sdk` ga bog'liq
- `MiniApp` interfeysini implement qiladi va to'liq `MiniAppManifest` 
  qaytaradi (id, title, icon, entryRoute, visibility)
- Qatlamlar: data/, domain/, application/, presentation/
- Kamida bitta `AsyncNotifier`, bitta ekran, bitta smoke test
- `apps/super_app/lib/bootstrap/mini_app_registry_provider.dart` da 
  ro'yxatga olinadi

Oldin reja ko'rsat, men tasdiqlaganimdan keyin kod yoz.
```

Claude sizga to'liq reja ko'rsatadi. Uni diqqat bilan o'qing:

- Qaysi fayllar yaratiladi?
- `mini_app_sdk` dan qaysi kontrakt implement qilinadi?
- Ro'yxatga qanday qo'shiladi?

Reja to'g'ri bo'lsa — `Accept plan`. Noto'g'ri bo'lsa — Claude'ga tuzattiring.

## Step 8: O'zgarishlarni tasdiqlash

```bash
melos run gen       # freezed / riverpod codegen
melos run analyze   # lintlar toza bo'lsin
melos run test      # testlar o'tsin
```

Faqat shundan keyin commit qiling:

```bash
git add .
git commit -m "feat(mini_apps/<name>): scaffold mini-app"
```

## Keyingi qadamlar

1. Yangi mini-app'ga haqiqiy funksionallik qo'shing — `MiniAppContext` orqali `network`, `analytics`, `storage` ishlatib ko'ring.
2. Har safar Claude xato qilsa — tuzating va **shu xatoni CLAUDE.md'ga qo'shing** (agar takrorlanishi mumkin bo'lsa).
3. Yangi platform service kerak bo'lsa — oldin `mini_app_sdk` ga abstract interface qo'shing, keyin alohida paket yarating. Mini-app'dan to'g'ridan-to'g'ri service paketga import **qilinmasin**.
4. `CLAUDE.local.md` fayliga o'z shaxsiy sozlamalaringizni yozing (masalan: "Men emulator ishlatmayman, real qurilmada test qilaman"). Bu fayl `.gitignore`da, faqat sizda qoladi.

## Muammolar

### "Claude platform qoidalariga rioya qilmayapti"

1. `/memory` — fayl yuklanayaptimi?
2. Agar yuklanmayotgan bo'lsa — Claude Code'ni qayta ishga tushiring.
3. Agar yuklanayotgan bo'lsa — qoidangiz juda umumiy bo'lishi mumkin. Aniqroq qiling. "Arxitekturaga rioya qil" emas, "Mini-app'dan `package:networking/` import qilinmasin, faqat `context.network` orqali" deb yozing.

### "Mini-app service paketga import qilgan va bu ko'rinmagan"

CI'da `import-graph-lint` job bor — u mini-app fayllarida taqiqlangan paketlarga importni topadi. Local tekshirish:

```bash
melos run analyze
```

Agar lint yetmasa, `.claude/rules/` ga qat'iyroq qoida qo'shing.

### "Kontekst oynasi tez to'lib qolyapti"

1. Uzoq `CLAUDE.md` fayllarini `@import` bilan ajrating.
2. Path-scoped rules'dan foydalaning (`paths:` frontmatter).
3. `/compact` o'rniga `/clear` ishlating yangi vazifa boshlaganda.

### "Yangi ishlab chiquvchi onboard qilmoqchiman"

`README.md` qisqa kirish, `README_monorepo.md` kundalik ish oqimi, `ARCHITECTURE.md` chuqur tushuntirish, `CLAUDE.md` esa Claude uchun. Ular ataylab ajratilgan — yangi odam `README.md` → `README_monorepo.md` → `ARCHITECTURE.md` tartibida o'qisin.
