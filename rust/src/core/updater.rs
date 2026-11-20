//! GitHub Releases tabanli otomatik guncelleme.
//!
//! Uygulama acilisinda (veya kullanici isterse) GitHub'daki en son surumu
//! kontrol eder. Daha yeni bir surum varsa, ilgili platformun ikili dosyasini
//! indirip uygulama kapandiktan sonra kendini guncelleyen bir yardimci betik
//! calistirir.

use crate::core::constants;
use serde::Deserialize;
use std::path::Path;

/// GitHub deposu sahibi.
pub const REPO_OWNER: &str = "Stegizm";
/// GitHub depo adi.
pub const REPO_NAME: &str = "SwiftX-Rust";

#[derive(Debug, Deserialize)]
struct GhRelease {
    tag_name: String,
    #[serde(default)]
    html_url: String,
    #[serde(default)]
    assets: Vec<GhAsset>,
}

#[derive(Debug, Deserialize)]
struct GhAsset {
    name: String,
    browser_download_url: String,
}

/// Bulunan guncelleme bilgisi.
#[derive(Debug, Clone)]
pub struct UpdateInfo {
    pub version: String,
    pub page_url: String,
    pub asset_url: Option<String>,
    pub asset_name: String,
}

fn target_asset_name() -> &'static str {
    if cfg!(target_os = "windows") {
        "swiftx.exe"
    } else {
        "swiftx"
    }
}

/// Surum numaralarini sayisal olarak karsilastirir.
pub fn is_newer(remote: &str, current: &str) -> bool {
    fn parts(s: &str) -> Vec<u32> {
        s.trim_start_matches('v')
            .split(['-', '+'])
            .next()
            .unwrap_or("")
            .split('.')
            .map(|p| p.trim().parse().unwrap_or(0))
            .collect()
    }
    let r = parts(remote);
    let c = parts(current);
    for i in 0..r.len().max(c.len()) {
        let a = r.get(i).copied().unwrap_or(0);
        let b = c.get(i).copied().unwrap_or(0);
        if a != b {
            return a > b;
        }
    }
    false
}

/// En son surumu GitHub'dan kontrol eder. Guncelleme varsa `Some` doner.
pub fn check() -> Result<Option<UpdateInfo>, String> {
    let url = format!("https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/releases/latest");
    let mut resp = ureq::get(&url)
        .header("User-Agent", "SwiftX")
        .header("Accept", "application/vnd.github+json")
        .call()
        .map_err(|e| e.to_string())?;
    let text = resp
        .body_mut()
        .read_to_string()
        .map_err(|e| e.to_string())?;
    let rel: GhRelease = serde_json::from_str(&text).map_err(|e| e.to_string())?;
    let remote = rel.tag_name.trim_start_matches('v').to_string();
    if !is_newer(&remote, constants::VERSION) {
        return Ok(None);
    }
    let want = target_asset_name();
    let asset_url = rel
        .assets
        .iter()
        .find(|a| a.name == want)
        .map(|a| a.browser_download_url.clone());
    Ok(Some(UpdateInfo {
        version: remote,
        page_url: rel.html_url,
        asset_url,
        asset_name: want.to_string(),
    }))
}

/// Guncellemeyi indirir ve uygulama kapandiktan sonra devreye girecek betigi baslatir.
pub fn download_and_apply(info: &UpdateInfo) -> Result<(), String> {
    let asset_url = info
        .asset_url
        .as_ref()
        .ok_or("Bu platform icin guncelleme dosyasi bulunamadi.")?;

    let updates_dir = constants::ensure_data_dir().join("updates");
    std::fs::create_dir_all(&updates_dir).map_err(|e| e.to_string())?;
    let new_path = updates_dir.join(&info.asset_name);

    let mut resp = ureq::get(asset_url)
        .header("User-Agent", "SwiftX")
        .call()
        .map_err(|e| e.to_string())?;
    let bytes = resp.body_mut().read_to_vec().map_err(|e| e.to_string())?;
    std::fs::write(&new_path, &bytes).map_err(|e| e.to_string())?;

    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = std::fs::set_permissions(&new_path, std::fs::Permissions::from_mode(0o755));
    }

    spawn_apply(&new_path)
}

#[cfg(unix)]
fn spawn_apply(new_path: &Path) -> Result<(), String> {
    let exe = std::env::current_exe().map_err(|e| e.to_string())?;
    let pid = std::process::id();
    let script = constants::ensure_data_dir().join("updates/apply.sh");
    let content = format!(
        "#!/bin/sh\n\
         while kill -0 {pid} 2>/dev/null; do sleep 0.3; done\n\
         tmp=\"{exe}.new\"\n\
         cp -f \"{new}\" \"$tmp\"\n\
         chmod +x \"$tmp\"\n\
         mv -f \"$tmp\" \"{exe}\"\n\
         setsid \"{exe}\" >/dev/null 2>&1 &\n\
         rm -f \"{script}\"\n",
        new = new_path.display(),
        exe = exe.display(),
        script = script.display()
    );
    std::fs::write(&script, content).map_err(|e| e.to_string())?;
    use std::os::unix::fs::PermissionsExt;
    let _ = std::fs::set_permissions(&script, std::fs::Permissions::from_mode(0o755));
    std::process::Command::new("sh")
        .arg(&script)
        .stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .spawn()
        .map_err(|e| e.to_string())?;
    Ok(())
}

#[cfg(windows)]
fn spawn_apply(new_path: &Path) -> Result<(), String> {
    use std::os::windows::process::CommandExt;
    let exe = std::env::current_exe().map_err(|e| e.to_string())?;
    let pid = std::process::id();
    let script = constants::ensure_data_dir().join("updates/apply.bat");
    let content = format!(
        "@echo off\r\n\
         :wait\r\n\
         tasklist /FI \"PID eq {pid}\" 2>nul | find \"{pid}\" >nul\r\n\
         if not errorlevel 1 (timeout /t 1 /nobreak >nul & goto wait)\r\n\
         move /Y \"{new}\" \"{exe}\" >nul\r\n\
         start \"\" \"{exe}\"\r\n\
         del \"{script}\" >nul 2>&1\r\n",
        new = new_path.display(),
        exe = exe.display(),
        script = script.display()
    );
    std::fs::write(&script, content).map_err(|e| e.to_string())?;
    const DETACHED_PROCESS: u32 = 0x0000_0008;
    const CREATE_NO_WINDOW: u32 = 0x0800_0000;
    std::process::Command::new("cmd")
        .arg("/C")
        .arg(&script)
        .creation_flags(DETACHED_PROCESS | CREATE_NO_WINDOW)
        .stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .spawn()
        .map_err(|e| e.to_string())?;
    Ok(())
}
