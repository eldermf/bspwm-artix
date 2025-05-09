

https://github.com/user-attachments/assets/e610dfa9-b751-4d08-8269-5759124c2134


# My Artix GNU/Linux Dotfiles (BspWM + OpenRC)

This repository contains my personal configuration files (dotfiles) for my Artix GNU/Linux system, featuring the BspWM window manager and the OpenRC init system.

## Included Configuration Files

This collection includes configuration files for various applications and system components, tailored to my specific workflow and preferences. You'll find configurations for:

* **BspWM:** My window manager configuration (`bspwmrc`).
* **Sxhkd:** Keybindings daemon configuration (`sxhkdrc`).
* **Polybar:** Status bar configuration (`config`).
* **Rofi:** Application launcher configuration (`config`).
* **Alacritty:** Terminal emulator configuration (`alacritty.yml`).
* **Vim/Neovim:** Text editor configuration (`.vimrc` or `init.vim`).
* **Zsh:** Shell configuration (`.zshrc`).
* **GTK:** GTK theme and icon settings (`settings.ini`, etc.).
* **And more...** (depending on my current setup)

## Installation Scripts

In addition to the configuration files, I've included some Bash scripts to help automate the installation process. These scripts typically handle tasks such as:

* Creating necessary directories.
* Symlinking the configuration files to their correct locations in your home directory.
* Potentially installing required packages (use with caution and review the scripts first).

**Please note:** These scripts are provided for convenience and are specific to my system setup. **Use them at your own risk.** It's highly recommended to review the scripts before running them to understand what they do and ensure they are compatible with your system.

## Usage

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/eldermf/bspwm-artix.git](https://github.com/eldermf/bspwm-artix.git) ~/.config/dotfiles
    ```
    
2.  **Navigate to the dotfiles directory:**
    ```bash
    cd ~/.config/dotfiles
    ```

3.  **Run the installation scripts:**
    ```bash
    ./install.sh  # Or a similar script name
    ```
    Make sure the script has execute permissions (`chmod +x install.sh`).

4.  **Review and customize:** After running the scripts, carefully review the configuration files in your home directory (`~/.config/bspwm`, `~/.config/sxhkd`, etc.) and customize them to your liking.

## Disclaimer

**Use these dotfiles and installation scripts at your own risk.** I am not responsible for any data loss or system instability that may occur as a result of using them. It is always a good idea to back up your existing configuration files before applying new ones.

## Further Enhancements (Optional)

* **Detailed Script Documentation:** You could add comments within the Bash scripts explaining each step.
* **Selective Installation:** Implement options in the installation scripts to allow users to choose which dotfiles they want to install.
* **Dependency Management:** The scripts could potentially check for and install necessary dependencies (again, with a clear warning and user confirmation).
* **System-Specific Branches:** If you use these dotfiles across multiple machines with slight variations, you could consider using Git branches to manage the differences.
* **Visual Showcase:** Adding a screenshot or GIF of your desktop setup can make your repository more visually appealing.
* **Explanation of Key Bindings:** You could include a section explaining some of your keybindings in `sxhkdrc`.
* **Theme Information:** Mention the GTK, icon, and other themes you are using.

Feel free to adapt and expand upon this `README.md` file as needed! Good luck with your dotfiles!
