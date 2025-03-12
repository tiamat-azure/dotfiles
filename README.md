
# 🚀 Comment installer zsh et Powerlevel10k (p10k) ?

Je vais vous guider pas à pas pour installer **zsh** (Z Shell) et le thème **Powerlevel10k** (p10k) sur Linux ou macOS. Allons-y ! 🛠️

---

## 1. 📥 Installer zsh

**zsh** est un shell puissant et personnalisable. Voici comment l’installer selon votre système :

### 🐧 Sur Linux (Ubuntu/Debian)
1. Ouvre un terminal.
2. Mets à jour les paquets :
   ```bash
   sudo apt update
   ```
3. Installe zsh :
   ```bash
   sudo apt install zsh
   ```
4. Vérifie l’installation ✅ :
   ```bash
   zsh --version
   ```

### 🌀 Sur Linux (Fedora)
```bash
sudo dnf install zsh
```

### 🍎 Sur macOS (via Homebrew)
1. Si Homebrew n’est pas installé, commence par l’installer :
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
2. Installe zsh :
   ```bash
   brew install zsh
   ```

### 🔧 Faire de zsh le shell par défaut
1. Vérifie où zsh est installé :
   ```bash
   which zsh
   ```
   (souvent `/bin/zsh` ou `/usr/bin/zsh`)
2. Change le shell par défaut :
   ```bash
   chsh -s /bin/zsh
   ```
3. Redémarre ton terminal ou reconnecte-toi pour appliquer les changements. 🔄

---

## 2. 🌟 Installer Oh My Zsh (optionnel, mais recommandé)

**Oh My Zsh** est un framework qui simplifie la gestion de zsh.

1. Installe Oh My Zsh avec cette commande :
   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```
2. Une fois installé, zsh se lancera automatiquement avec Oh My Zsh. 🎊

---

## 3. 🎨 Installer Powerlevel10k (p10k)

**Powerlevel10k** est un thème rapide et personnalisable pour zsh.

### 📋 Prérequis
- **Oh My Zsh** doit être installé (voir ci-dessus).
- Une police compatible avec les glyphes (comme **Meslo Nerd Font**) est conseillée pour un affichage au top. Téléchargez-la ici : [Nerd Fonts](https://www.nerdfonts.com/font-downloads). Installez-la et configurez votre terminal pour l’utiliser. ✍️

### 🛠️ Installation
1. Installe Powerlevel10k :
   ```bash
   git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
   ```
2. Configure zsh pour utiliser Powerlevel10k :
   - Ouvre le fichier `~/.zshrc` avec un éditeur (ex. `nano ~/.zshrc`).
   - Modifie la ligne du thème pour :
     ```bash
     ZSH_THEME="powerlevel10k/powerlevel10k"
     ```
   - Sauvegarde et ferme (Ctrl+O, Enter, Ctrl+X pour nano). 💾
3. Recharge la configuration :
   ```bash
   source ~/.zshrc
   ```

### ⚙️ Configuration de Powerlevel10k
- La première fois que tu charges zsh, Powerlevel10k lancera un assistant interactif. 🎯
- Suis les instructions pour personnaliser ton prompt (icônes, style, etc.).
- Pour reconfigurer plus tard :
   ```bash
   p10k configure
   ```

---

## 4. ✅ Vérification finale
- Ferme et rouvre ton terminal.
- Si tout est bien installé, tu verras un prompt stylé par Powerlevel10k. 😎
