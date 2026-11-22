# বিডি ল্যান্ড প্রো (BDLandPro) - অটোমেটিক ক্লাউড APK বিল্ড নির্দেশিকা

আপনার লোকাল কম্পিউটারে কোনো ভারী Android SDK, Android Studio বা Flutter ইনস্টল করার প্রয়োজন **নেই**! সম্পূর্ণ অ্যাপ্লিকেশনটি ক্লাউডে GitHub Actions-এর মাধ্যমে সম্পূর্ণ স্বয়ংক্রিয়ভাবে কম্পাইল হয়ে রেডি-টু-ইউজ `.apk` ফাইলে রূপান্তরিত হবে।

---

## 🚀 মাত্র ৩টি সহজ ধাপে আপনার ফোনের জন্য `.apk` ডাউনলোড করুন:

### ধাপ ১: GitHub-এ রিপোজিটরি তৈরি ও কোড আপলোড
১. [GitHub](https://github.com/) এ লগইন করুন এবং একটি নতুন রিপোজিটরি (New Repository) তৈরি করুন (নাম দিতে পারেন: `BDLandPro`).
২. রিপোজিটরিটি `Public` বা `Private` যে কোনোটি রাখতে পারেন।
৩. আপনার কম্পিউটারের এই `BDLandPro_OpenSource` ফোল্ডারের ফাইলগুলো GitHub-এ পুশ (Push) বা আপলোড করুন:
   ```bash
   cd BDLandPro_OpenSource
   git init
   git add .
   git commit -m "feat: complete bdland pro release"
   git branch -M main
   git remote add origin https://github.com/<আপনার-ইউজারনেম>/BDLandPro.git
   git push -u origin main
   ```
*(অথবা গিটহাবে সরাসরি `Add file` -> `Upload files` দিয়ে সব ফাইল ড্র্যাগ অ্যান্ড ড্রপ করতে পারেন)*

---

### ধাপ ২: GitHub Actions বিল্ড পর্যবেক্ষণ
১. কোড পুশ করার সাথে সাথে GitHub-এর **Actions** ট্যাবে যান।
২. আপনি দেখতে পাবেন `Build Android APK` নামের একটি অটোমেটিক ওয়ার্কফ্লো চালু হয়েছে।
৩. এটি ক্লাউডের উবুন্টু সার্ভারে জাভা ১৭ এবং ফ্ল্যাটার পরিবেশ সেটআপ করে প্রজেক্টের সমস্ত ইউনিট টেস্ট চালাবে এবং রিলিজ এপিকে কম্পাইল করবে (সাধারণত ২ থেকে ৩ মিনিট সময় লাগে)।
৪. বিল্ড সম্পন্ন হলে একটি সবুজ টিকচিহ্ন (Green Checkmark) দেখতে পাবেন।

---

### ধাপ ৩: সরাসরি `.apk` ডাউনলোড ও ফোনে ইনস্টল
১. সফল বিল্ডটির ওপর ক্লিক করে ভেতরে প্রবেশ করুন।
২. স্ক্রিনের নিচের দিকে **Artifacts** সেকশনে যান।
৩. সেখানে **`app-release-apk`** নামের একটি জিপ ফাইল দেখতে পাবেন। এটিতে ক্লিক করে ডাউনলোড করুন।
৪. জিপ ফাইলটি আনজিপ করলেই আপনি পেয়ে যাবেন প্রস্তুতকৃত **`app-release.apk`**।
৫. আপনার অ্যান্ড্রয়েড ফোনে ফাইলটি পাঠিয়ে ইনস্টল করুন এবং নির্ভুলভাবে জমি পরিমাপ, খতিয়ানের হিস্যা ও ফারায়েজ বণ্টন শুরু করুন!

---

## 🛠️ বিল্ডে ব্যবহৃত প্রযুক্তি ও ফিচারসমূহ:
- **Flutter Framework:** stable channel (v3.29+)
- **CI/CD:** GitHub Actions (`subosito/flutter-action@v2` + `actions/upload-artifact@v4`)
- **Fonts:** Hind Siliguri (Google Fonts)
- **Architecture:** Feature-first Clean Architecture, 100% Offline-First.
