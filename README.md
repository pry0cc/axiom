# README

# Project Axiom

# Axiom

Project Axiom is a set of utilities for managing a small dynamic infrastructure setup for bug bounty and pentesting.

**Axiom right now is perfect for teams as small as one person, without costing you much at all to run.**

When I first began trying to get up and running my own dynamic cloud hacking setup, I noticed that the array of tools and ecosystems were so large, and there were 50 different ways to do just about everything, do I use ansible for provisioning on server boot, do I load ansible with packer? How much do I configure for image builds? There were a few ‘red team’ infra setup tools and aids, but they all required so much legwork just to get off the ground. It felt like in a lot of cases people were just publishing what they use without any help/documentation on getting started.

The other situation I faced, when looking at other pentesting distros, is that they had very little support for a lot of the common tools I was using in my day-day bug bounty and red team work. Distro’s such as Kali were great for traditional netsec, but for bug bounty and large-infrastructure projects they lacked a lot of the great stuff

Specifically Go tools, lots of really awesome small Go utilities such as the array of masterpieces from likes of [Tom Hudson](https://github.com/tomnomnom/), [Luke Stephens](https://github.com/hakluke) and [Jason Haddix](https://github.com/jhaddix). Bug bounty has become overrun with fancy and clever Go utilities usually stiched together in bash one liners.

Setting up your own ‘hacking vps’, to catch shells, run enumeration tools, scan, let things run in the background in a tmux window, used to be an afternoon project. You would run through and install all the tools you need manually, configure your ZSH, configure vim, configure tmux.

With Axiom, you just need to run a single command to get setup, and then you can use the Axiom toolkit scripts to spin up and down your new hacking VPS.

![https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled.png](https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled.png)

Run `axiom-init` and watch as a new instance is created in under 2 minutes containing everything you could ever want or need to run your reconaissance for your pentest, catch a shell in netcat, or maybe you want to VPN through (axiom comes with support for one-click deployment profiles for things like openvpn, `axiom-deploy openvpn` and you soon have a fully configured openvpn server.

When you’re finished, simply bring down the instance with `axiom-rm your-instance-12` a quick confirmation dialog, and your box is gone! It’s no longer costing you anything to run.

![https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled%201.png](https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled%201.png)

The init script, packed with `notify-send` hooks, can be run entirely headlessly while it spins up your machine of choice.

![https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled%202.png](https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled%202.png)

In this toolkit, I have attempted to make setting up your own cloud hacking box as simple as possible with as little touch from you as is necessary.

To aid you, I have created an array of bash wrappers to get started. The axiom base image has been developed with bug hunters and lean teams to quickly initialize and dispose of infrastructure (and actually have the tools that they use daily, preinstalled).

![https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled%203.png](https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled%203.png)

`axiom-ssh host` is used to connect to your machines, to see which machines you have available, use `axiom-ls`

![https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled%204.png](https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled%204.png)

# One-liner setup with `Axiom-configure`

![https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled%205.png](https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled%205.png)

![https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled%206.png](https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled%206.png)

# Installation

## Bash One Liner

```
bash <(curl -s https://raw.githubusercontent.com/pry0cc/axiom/master/interact/axiom-configure)
```

# OS Support

I am trying to add as many different operating systems to support, mainly going for *nix such as MacOS, Ubuntu, Debian, Arch Linux, and maybe Kali in the future.

The main trouble here is just the dependencies.

- MacOS - Supported
- Ubuntu - Supported
- Debian - Semi-Supported - Planned
- Arch Linux - Semi-Support - Planned
- Kali - Unknown

# Dependencies

- Packer - Tested with v1.5.6
- fzf - Tested with 0.21.1
- doctl - Tested with 1.43
- jq - Tested with 1.6 (latest is better for this one)

Packer is pretty easy everywhere, although manual (its really important you get the right version, if its too old, then the var-file syntax will fail.

fzf is everywhere too, doctl can be a bit tricky (using snap to do that on ubuntu, ew). jq needs to be recent, they updated the command syntax!

# Fun Screenshots

A fun out of the box one-liner that gets subdomains with subfinder, looks them up and resolves them, passes the

![https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled%207.png](https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Untitled%207.png)

# Packages To Date

- [x]  aquatone
- [x]  httprobe
- [x]  subfinder
- [x]  assetfinder
- [x]  gf w/ filters
- [x]  masscan
- [x]  kxss
- [x]  jq
- [x]  SecLists
- [x]  gobuster
- [x]  nmap
- [x]  waybackurls
- [x]  amass
- [x]  anti-burl
- [x]  Golang (setup, path configured, latest version)
- [x]  hakrawler
- [x]  Zdns
- [x]  ffuf
- [x]  gau
- [x]  dalfox
- [x]  dirb
- [x]  subjack
- [x]  SQLMap
- [x]  fbrobe
- [x]  getjs
- [x]  openvpn