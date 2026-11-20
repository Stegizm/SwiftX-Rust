<div align="center">

# SwiftX Browser

**Hızlı, hafif ve açık kaynaklı masaüstü web tarayıcısı.**

Rust ile yazılmıştır · [tao](https://crates.io/crates/tao) + [wry](https://crates.io/crates/wry) · Linux & Windows

[![Release](https://img.shields.io/github/v/release/Stegizm/SwiftX-Rust?sort=semver&color=blueviolet)](https://github.com/Stegizm/SwiftX-Rust/releases)
[![Build](https://github.com/Stegizm/SwiftX-Rust/actions/workflows/release.yml/badge.svg)](https://github.com/Stegizm/SwiftX-Rust/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-linux%20%7C%20windows-2ea44f.svg)](#kurulum)

</div>

---

## İçindekiler

- [Özellikler](#özellikler)
- [Kurulum](#kurulum)
- [Kullanım](#kullanım)
- [Klavye Kısayolları](#klavye-kısayolları)
- [Otomatik Güncelleme](#otomatik-güncelleme)
- [Geliştirme](#geliştirme)
- [Proje Yapısı](#proje-yapısı)
- [Sürüm Yayınlama](#sürüm-yayınlama)
- [Katkı](#katkı)
- [Lisans](#lisans)

## Özellikler

| Kategori | Özellikler |
| --- | --- |
| **Sekmeler** | Çoklu sekme, sekme uyutma (hafıza tasarrufu), renkli sekmeler, orta tık ile kapatma |
| **Gezinti** | Geri / ileri / yenile / ana sayfa, adres çubuğu ve arama birleşik girişi |
| **İçerik** | Yer imleri çubuğu, son 500 kayıtlı geçmiş, indirme yöneticisi |
| **Gizlilik** | URL tabanlı reklam & izleyici engelleyici, izin yönetimi (kamera, mikrofon, konum…) |
| **Okuma** | Sayfa içinde arama, otomatik karanlık mod, yumuşak kaydırma, okuma modu |
| **Eklentiler** | Dark Reader, No Ads, Page Speed, Privacy Guard, Read Mode |
| **Oturum** | Oturum geri yükleme, kalıcı ayarlar (`settings.json`) |
| **Diğer** | Tam ekran, zoom, geliştirici araçları, otomatik güncelleme |

## Kurulum

### Hazır paketler (önerilir)

[Releases](https://github.com/Stegizm/SwiftX-Rust/releases) sayfasından işletim sistemine uygun dosyayı indir:

| Platform | Dosya |
| --- | --- |
| Linux (x86_64) | `swiftx-linux-x86_64.tar.gz` |
| Windows (x86_64) | `swiftx-windows-x86_64.zip` |

**Linux**

```bash
tar -xzf swiftx-linux-x86_64.tar.gz
cd swiftx && ./swiftx
```

**Windows**

Zip dosyasını çıkar ve `swiftx.exe` dosyasını çalıştır.

> Paketlerin içinde çalıştırılabilir dosya ve `resources/` klasörü (ana sayfa, görseller) bulunur.

### Kaynaktan derleme

```bash
git clone https://github.com/Stegizm/SwiftX-Rust.git
cd SwiftX/rust
cargo build --release
./target/release/swiftx
```

**Linux bağımlılıkları**

| Dağıtım | Komut |
| --- | --- |
| Debian / Ubuntu | `sudo apt install libwebkit2gtk-4.1-dev libgtk-3-dev libsoup-3.0-dev libjavascriptcoregtk-4.1-dev` |
| Arch | `sudo pacman -S webkit2gtk-4.1 gtk3` |
| Fedora | `sudo dnf install webkit2gtk4.1-devel gtk3-devel` |

**Windows:** WebView2 Runtime gerekir (Windows 10/11'de varsayılan olarak yüklüdür).

> **Wayland notu:** wry'nin Linux arka ucu alt-web görünümleri için X11 kullanır. Uygulama açılışta
> `GDK_BACKEND=x11` seçerek XWayland üzerinden çalışır; saf Wayland oturumunda XWayland kurulu olmalıdır.

## Kullanım

Uygulama açıldığında ana sayfa yüklenir. Adres çubuğuna bir URL yaz (`example.com`) veya doğrudan
arama terimi gir. Sol menüden (`☰`) ana sayfaya dön, eklentileri ya da ayarları aç. Sağ panelden
geçmişi ve indirmeleri görüntüle.

## Klavye Kısayolları

| Kısayol | İşlev | Kısayol | İşlev |
| --- | --- | --- | --- |
| `Ctrl+T` | Yeni sekme | `Ctrl+B` | Sol menü |
| `Ctrl+W` | Sekmeyi kapat | `Ctrl+L` | Adres çubuğuna odaklan |
| `Ctrl+R` / `F5` | Yenile | `Ctrl+D` | Yer imine ekle |
| `Alt+←` / `Alt+→` | Geri / ileri | `Ctrl+H` / `Ctrl+J` | Geçmiş / indirmeler |
| `Ctrl+F` | Sayfada ara | `Ctrl+S` | Yer imlerini dışa aktar |
| `Ctrl++` / `Ctrl+-` / `Ctrl+0` | Yakınlaştır / uzaklaştır / sıfırla | `F11` / `F12` | Tam ekran / geliştirici araçları |

## Otomatik Güncelleme

SwiftX açılışta GitHub'daki en son sürümü kontrol eder. Daha yeni bir sürüm varsa bildirim gösterir;
**Ayarlar → Güncellemeler** bölümünden yeni ikili dosyayı indirip uygulamayı yeniden başlatarak
günceller. Kontrolü elle çalıştırmak için:

```bash
./swiftx --check-update
```

## Geliştirme

```bash
cd rust
cargo build            # hata ayıklama derlemesi
cargo run              # çalıştır
cargo test             # testler
cargo clippy           # statik analiz
cargo fmt --check      # biçim denetimi
```

**Ortam değişkenleri**

| Değişken | Açıklama |
| --- | --- |
| `SWIFTX_DATA_DIR` | Veri dizinini geçersiz kılar (ayarlar, geçmiş, önbellek) |
| `SWIFTX_RESOURCES` | Kaynak (ana sayfa/görsel) dizinini geçersiz kılar |
| `SWIFTX_DEBUG=1` | Ayrıntılı günlük kaydı |
| `SWIFTX_SELFTEST=1` | Dahili arayüz self-test'ini çalıştırır |

## Proje Yapısı

```
SwiftX/
├── rust/
│   ├── src/
│   │   ├── main.rs        # giriş noktası / olay döngüsü
│   │   ├── app.rs         # koordinatör (pencere, sekmeler, servisler)
│   │   ├── ipc.rs         # arayüz <-> çekirdek mesaj protokolü
│   │   ├── core/          # sabitler, modeller, depolama, servisler, güncelleyici
│   │   ├── engine/        # web görünümü, reklam engelleme, enjekte scriptler
│   │   └── ui/            # gömülü chrome arayüzü (HTML/CSS/JS)
│   ├── resources/         # ana sayfa + görseller
│   └── tests/             # birim / mantık testleri
├── .github/workflows/     # release otomasyonu
├── setup.sh               # GitHub'a yayınlama yardımcısı
└── README.md
```

## Sürüm Yayınlama

Her `v*` etiketi push edildiğinde veya GitHub'da bir release yayınlandığında GitHub Actions Linux ve
Windows için çalıştırılabilir paketleri otomatik üretir.

```bash
# 1) Sürümü yükselt: rust/Cargo.toml ve rust/src/core/constants.rs
# 2) Yayınla:
GITHUB_TOKEN=ghp_xxxxxxxx TAG=v0.3.1 ./setup.sh
```

`setup.sh`, `gh` (GitHub CLI) gerektirmez; bir Personal Access Token (`repo` + `workflow` yetkili)
ile depoyu oluşturur/push eder ve etiketi gönderir. Aynı etiketi yeniden yayınlamak için `FORCE_TAG=1`
kullanılabilir.

## Katkı

Katkılar memnuniyetle karşılanır. Lütfen önce bir **issue** açarak değişikliği tartışın, ardından
özellik dalı açıp pull request gönderin:

```bash
git checkout -b ozellik/yeni-ozellik
cargo fmt && cargo clippy && cargo test
```

## Lisans

Bu proje **MIT** lisansı ile dağıtılmaktadır. Ayrıntı için [LICENSE](LICENSE) dosyasına bakın.

---

<div align="center">
<sub>SwiftX — başlangıçta Python + QtWebEngine ile geliştirildi, <b>v0.3.0</b> ile tamamen Rust'a taşındı.</sub>
</div>
