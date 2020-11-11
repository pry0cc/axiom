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

**Axiom is a dynamic infrastructure framework** to efficiently work with multi-cloud enviornments, build and deploy repeatable infrastructure focussed on offensive and defensive security. 

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
-   [Contributors](#contributors)

## Demo
<img src="https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/axiom-init-demo.gif" alt="" height=443 width=666px>

## $100 Free Credit
The original and best supported provider for Axiom is Digital Ocean! If you're signing up for a new Digital Ocean account, [please use my link!](https://m.do.co/c/bd80643300bd ) 

## Support
If you like Axiom and it saves you time, money or just brings you happy feelings, please show your support through sponsorship! Click the little sponsor button in the header and sponsor for as little as $1 per month :)

Or buy me a coffee to keep me powered :)
<a href="https://www.buymeacoffee.com/pry0cc" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-black.png" alt="Buy Me A Coffee" style="height: 5px !important;width: 25px !important;" ></a>

---

# OS Support
- MacOS - Supported
- Ubuntu - Supported
- Debian - Supported
- Arch Linux - Supported

# Contributors
We've had some really fantastic additions to axiom, great feedback through issues, and perseverence through our heavy beta phase!

A list of all contributors can be found [here](https://github.com/pry0cc/axiom/graphs/contributors), thank you all!

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
