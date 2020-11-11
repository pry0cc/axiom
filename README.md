<h1 align="center">
  <img src="screenshots/axiom-logo-new.png" alt="axio m" width="270px"></a>
  <br>
</h1>

[![License](https://img.shields.io/badge/license-MIT-_red.svg)](https://opensource.org/licenses/MIT)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/pry0cc/axiom/issues)
[![Follow on Twitter](https://img.shields.io/twitter/follow/pry0cc.svg?logo=twitter)](https://twitter.com/pry0cc)

<p align="center">
<a href="https://github.com/pry0cc/axiom/wiki" target="_blank"> <img src="https://raw.githubusercontent.com/projectdiscovery/nuclei/master/static/read-the-docs-button.png" height="42px"/></a>
</p>

**Axiom is dynamic infrastructure framework** to efficiently work with multi-cloud enviornments, build and deploy repeatable infrastructure focussed on offensive and defensive security. 

Axiom works by pre-installing your tools of choice onto a 'base image', and then using that image to deploy fresh instances. From there, you can connect and instantly gain access to many tools useful for both bug hunters and pentesters. With the power of immutable infrasutrcture, most of which is done for you, you can just spin up 15 boxes, perform a distributed nmap/ffuf/screenshotting scan, and then shut them down.  

## Installation

(You will need curl, which is not installed by default on Ubuntu 20.04, if you get a "command not found" error, run `sudo apt update && sudo apt install curl`)

```
bash <(curl -s https://raw.githubusercontent.com/pry0cc/axiom/master/interact/axiom-configure)
```

## Resources

-   [Introduction](https://github.com/pry0cc/axiom/wiki)
-   [Quickstart](https://github.com/pry0cc/axiom/wiki/A-Quickstart-Guide)
    - [Fleets](https://github.com/pry0cc/axiom/wiki/Fleets)
    - [Scans](https://github.com/pry0cc/axiom/wiki/Scans)
-   [Usage](#usage)
-   [Demo](#demo)
-   [Story](https://github.com/pry0cc/axiom/wiki/The-Story)
-   [Installation Instructions](https://github.com/pry0cc/axiom/wiki/0-Installation)
    -   [Easy Install](#installation)
    -   [Manual Install](https://github.com/pry0cc/axiom/wiki/0-Installation#Manual)
-   [Scan Templates](#scan-templates)
-   [Thanks](#thanks)

## Demo
<img src="https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/axiom-init-demo.gif" alt="" height=443 width=666px>

## $100 Free Credit

To obtain a Digitalocean API Key for this to work, you can sign up with my referral link and get $100 free credit to try it out!

I also get a small kickback so if you liked this project please use my link :)

https://m.do.co/c/bd80643300bd 

<a href="https://www.buymeacoffee.com/pry0cc" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-black.png" alt="Buy Me A Coffee" style="height: 10px !important;width: 50px !important;" ></a>

Happy hacking! :)

---

# OS Support
- MacOS - Supported
- Ubuntu - Supported
- Debian - Supported
- Arch Linux - Supported

# Contributors
Below is a list of amazing people that have contributed to this project! Thank you to everybody on this list! If I missed you out, just make a PR for this readme and I'll make sure you're added! There are some amazing people here :)
- maverickNerd
- t3chbits
- paralax
- mcrmonkey
- razcodesdotdev
- icyphox
- Dan GITC (@ghostinthecable)
- myrdn
- Cgboal
- ericho
- mswell
- kpcyrd
- s0mdev (made the logo!!!)
- connell (@cmcginley)

# Packages To Date

- [x]  Golang (setup, path configured, latest version)
- [x]  gowitness
- [x]  aquatone
- [x]  httprobe
- [x]  subfinder
- [x]  assetfinder
- [x]  gf
- [x]  anew
- [x]  masscan
- [x]  sn0int
- [x]  kxss
- [x]  jq
- [x]  SecLists
- [x]  gobuster
- [x]  nmap
- [x]  waybackurls
- [x]  amass
- [x]  anti-burl
- [x]  hakrawler
- [x]  zdns
- [x]  zmap
- [x]  ffuf
- [x]  gau
- [x]  dirb
- [x]  subjack
- [x]  SQLMap
- [x]  fbrobe
- [x]  getjs
- [x]  openvpn
- [x]  projectdiscovery chaos-client
- [x]  projectdiscovery nuclei
- [x]  projectdiscovery chaos
- [x]  projectdiscovery shuffledns
- [x]  dnsprobe
- [x]  dnsvalidator
- [x]  urlprobe
- [x]  oh-my-zsh
- [x]  tmux
- [x]  masscan
- [x]  massdns
- [x]  subgen
- [x]  proxychains w/ Tor setup
- [x]  mosh
- [x]  docker
- [x]  metasploit
- [x]  dalfox
- [x]  subjack

