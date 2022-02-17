# Config process (post install)

Before anything, make sure that everything is synced and updated

```sh
pacman -Syu
```

&nbsp;
## Installing essential packages

- AMD GPU drivers

GPU-PACKAGES:
> mesa lib32-mesa libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau opencl-mesa lib32-opencl-mesa vulkan-mesa-layers lib32-vulkan-mesa-layers vulkan-radeon lib32-vulkan-radeon xf86-video-amdgpu

```sh
sudo pacman -S <GPU-PACKAGES>
```

&nbsp;

- Audio drivers

AUDIO-PACKAGES:
> pipewire pipewire-media-session pipewire-alsa pipewire-jack pipewire-pulse gst-plugin-pipewire

```sh
sudo pacman -S <AUDIO-PACKAGES>
```

&nbsp;

- Fonts

FONTS-PACKAGES:
> noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-fira-code cantarell-fonts

```sh
sudo pacman -S <FONTS-PACKAGES>
```

&nbsp;

- UI framework and toolkits

UIFW-PACKAGES:
> gtk4 gtk3 qt5-base qt5-tools qt5-script qt5-translations qt6-base qt6-tools qt6-translations

```sh
sudo pacman -S <UIFW-PACKAGES>
```

&nbsp;

- X.org

X.ORG-PACKAGES:
> xorg-server xorg-xinit

```sh
sudo pacman -S <X.ORG-PACKAGES>
```

&nbsp;

- DM, Compositor, WM and Taskbar/Launcher

DE-PACKAGES:
> lightdm lightdm-gtk-greeter picom icewm tint2

```sh
sudo pacman -S <DE-PACKAGES>
```

&nbsp;

- Terminal

```sh
sudo pacman -S kitty
```

&nbsp;
## Configure X.Org xinit

```sh
cp /etc/X11/xinit/xinitrc ~/.xinitrc
nano ~/.xinitrc
```

After the "start some nice programs" section, delete everything (after the line with "fi" in it); And in place of it, set the programs to be started with xinit.

> start some nice programs
> 
> if [ -d /etc/X11/xinit/xinitrc.d ] ; then
> for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
> [ -x "$f" ] && . "$f"
> done
> unset f
> fi
>
> twm &
> xclock -geometry 50x50-1+1 &
> xterm -geometry 80x50+494+51 &
> xterm -geometry 80x20+494-0 &
> exec xterm -geometry 80x66+0+0 -name login
