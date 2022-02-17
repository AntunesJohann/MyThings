# Description [TODO];
Nada demais aqui. Gosto de ser consistente com minha instalação do Arch, então aqui está um tutorial que escrevi para... Bom... Eu mesmo
&nbsp;
This is my (Johann/X3Hann) step-by-step Arch install.

&nbsp;

----

# Installation ritual

## 01| After booting into the ArchLinux.iso

- Load the correct keyboard layout. Run `loadkeys` with the desired keyboard layout after it.

```sh
loadkeys <VALID-KEYBOARD-HERE>
```

Some valid examples are:

<pre class="tab">
br-abnt2
uk
us
</pre>

&nbsp;
## 02| Ensure proper system clock accuracy

```sh
timedatactl set-ntp true
```

&nbsp;
## 03| Finding, partitioning, formatting and mounting the SSD/HDD
### Partitioning

- Use `fdisk -l` to find the desired storage and run cfdisk with the path to the disk to format.
- Then, run `cfdisk` to edit the selected one.

```sh
cfdisk /dev/<DESIRED_STORAGE>
```

- Now, inside cfdisk, set the following settings:
   * Disk Partition Table: GPT

| Part. Order | Part. Type | Size |
| ----------- | ---------- | ---- |
| First | EFI System | Minimum of 260MiB (More than 1GiB is too much) |
| Second | Linux swap | The same as RAM (not necessary more than 8GiB) |
| Third | Linux root (x86-64) | 32GiB is plenty |
| Fourth | Linux home | The rest of the available space |

- Write everything to disk and then exit.


### Formatting

- Now you'll format every partition created and give them a label too.

```sh
mkfs.fat -F32 -n EFI-PART /dev/sda1
mkswap -L SWAP-PART /dev/sda2
mkfs.btrfs -L ROOT-PART /dev/sda3
mkfs.btrfs -L HOME-PART /dev/sda4
```

### Mounting:
- Now its just a matter of mounting these newly created partitions to there respective mounting points. Some [mounting points] will need to be created beforehand.

```sh
mount /dev/sda3 /mnt
mkdir /mnt/boot
mkdir /mnt/home
mount /dev/sda1 /mnt/boot
mount /dev/sda4 /mnt/home
swapon /dev/sda2
```

&nbsp;
## 04| Installing the system with Pacstrap

- Install the following packages with `pacstrap`:

> base base-devel linux-zen linux-firmware linux-zen-headers systemd-libs amd-ucode dosfstools mtools btrfs-progs nano python networkmanager bluez crda nss firewalld man-db man-pages git cmake clang zsh udisks2 flatpak cockpit

```sh
pacstrap /mnt <PACKAGES> --ignore "linux"
```

&nbsp;
## 05| Generating and editing fstab
- Create fstab using disks partition labels using `genfstab`.

```sh
genfstab -L /mnt >> /mnt/etc/fstab
```

- Now you just need to replace "relatime" with "noatime" within the fstab file. Edit it with _nano_.


```sh
nano /mnt/etc/fstab
```

&nbsp;
## 06| Entering the newly installed system

```sh
arch-chroot /mnt
```

&nbsp;

---
## Preparing the installed system...
&nbsp;

## 07| Configuring _pacman.conf_ and sudoers (_sudo_)
### Editing pacman.conf file.

```sh
nano /etc/pacman.conf
```

Uncomment the following lines:

<pre class="tab">
...
#Color
#VerbosePkgLists
...
#[multilib]
#Include = /etc/pacman.d/mirrorlist
...
</pre>

And add the following one after "VerbosePkgLists":

<pre class="tab">
ILoveCandy
</pre>

### Update repos as needed

```sh
pacman -Syu
```

### Configuring sudo (sudoers)

- Uncomment the line "#%wheel ALL=(ALL) ALL". Edit it with `nano` through `visudo`.

```sh
EDITOR=nano visudo
```

&nbsp;
## 08| Setting timezone, adjtime, locale(s) and keyboard layout permanently
### Set timezone

- Valid time zones can be found inside _/usr/share/zoneinfo/_

```sh
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
```

### Generating adjtime

```sh
hwclock --systohc
```

### Generate locales
- One can either use `echo` to write the desired locale code on the last line of _locale.gen_ file, or use `nano` to uncomment the already existing one inside it. Its faster to use `echo`...

```sh
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
```

After it, generate the locales:

```sh
locale-gen
```
### Now set the appropriate keyboard layout:

```sh
echo 'KEYMAP=br-abnt2' >> /etc/vconsole.conf
```

&nbsp;
## 09| Setting a hostname, editing hosts file, enabling networkmanager and firewalld services

### Setting the hostname

```sh
echo '<HOSTNAME_HERE>' >> /etc/hostname
```

### Preparing the hosts file

```sh
nano /etc/hosts
```

- Edit it so it have at least these three lines:

<pre class="tab">
127.0.0.1 localhost
::1       localhost
127.0.1.1 &lt;HOSTNAME_HERE&gt;.&lt;DOMAINNAME_HERE&gt; &lt;HOSTNAME_HERE&gt;
</pre>

### Enabling _networkmanager_, _firewalld_ and _cockpit_ services on boot

```sh
systemctl enable NetworkManager.service
systemctl enable firewalld.service
systemctl enable cockpit.socket
```

&nbsp;
## 10| Configuring _mkinitcpio_
Lets set an uncompressed initcpio image cause every millisecond counts on boot time.

### Editing mkinitcpio.conf
- Use `nano` to add the line "COMPRESSION=cat" just below "#COMPRESSION="lz4"".

```sh
nano /etc/mkinitcpio.conf
```

### Rebuild the initcpio image again.

```sh
mkinitcpio -p linux-zen
```

&nbsp;
## 11| Installing and configuring the bootloader

### Installing

```sh
bootctl install
```

### Configuring default and fallback entries

- Using `nano`, create a default entry for the bootloader to load (this will be called _default.conf_).

```sh
nano /boot/loader/entries/default.conf
```

- The first one should be as follows:

<pre class="tab">
title    ArchLinux
linux    /vmlinuz-linux-zen
initrd   /amd-ucode.img
initrd   /initramfs-linux-zen.img
options  root="LABEL=ROOT-PART" rw
</pre>

- Now to configure a fallback entry, do the same as the default one above, but in a new file (lets call it _default-fallback.conf_) and changing the second initrd from "initramfs-linux-zen.img" to "initramfs-linux-zen-fallback.img".


### Configuring the bootloader itself

```sh
nano /boot/loader/loader.conf
```

- Add at least the _default_ line pointing to the entry that you just created. **WARNING**: No tabs should be used as indentation here, use spaces instead.

<pre class="tab">
default        default.conf
console-mode   auto
editor         no
</pre>

&nbsp;
## 12| Creating superuser's (root) password and setting the main user account

- When under _arch-chroot_ we'll be logged as superuser, so to change its password just run `passwd` without a username.

```sh
passwd
```

### Setting the user name, shell, groups and password:

```sh
useradd <USERNAME_HERE> -m -s /usr/bin/zsh -G wheel,adm,uucp,storage,video,audio
passwd <USERNAME_HERE>
```

&nbsp;
## 13| Reboot and add cockpit to the firewall

```sh
reboot
```

### Allowing cockpit through the firewall

```sh
firewall-cmd --add-service=cockpit --zone=public --permanent
firewall-cmd --reload
```
