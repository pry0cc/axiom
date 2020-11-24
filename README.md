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

**Axiom is a dynamic infrastructure framework** to efficiently work with multi-cloud environments, build and deploy repeatable infrastructure focussed on offensive and defensive security. 

Axiom works by pre-installing your tools of choice onto a 'base image', and then using that image to deploy fresh instances. From there, you can connect and instantly gain access to many tools useful for both bug hunters and pentesters. With the power of immutable infrasutrcture, most of which is done for you, you can just spin up 15 boxes, perform a distributed nmap/ffuf/screenshotting scan, and then shut them down.  

Because you can create many disposable instances very easily, axiom allows you to distribute scans of many different tools including ffuf, dnsprobe, gowitness, httpx, nmap & masscan. Once installed and setup, you can distribute a scan of a large set of targets across 10-15 instances within minutes and get results extremely quickly. This is called [axiom-scan](https://github.com/pry0cc/axiom/wiki/Scans).

Axiom supports several cloud providers, eventually, axiom should be completely cloud agnostic allowing unified control of a wide variety of different cloud environments with ease. Currently, DigitalOcean & IBM Cloud are officially supported providers. Google Compute is partially implemented. AWS & Azure are on the roadmap. If you would like prioritization of a feature or provider implementation, please contact me @pry0cc on Twitter and we can discuss :)

## Resources

-   [Introduction](https://github.com/pry0cc/axiom/wiki)
-   [Quickstart](https://github.com/pry0cc/axiom/wiki/A-Quickstart-Guide)
    - [Fleets](https://github.com/pry0cc/axiom/wiki/Fleets)
    - [Scans](https://github.com/pry0cc/axiom/wiki/Scans)
-   [Demo](#demo)
-   [Story](https://github.com/pry0cc/axiom/wiki/The-Story)
-   [Installation Instructions](https://github.com/pry0cc/axiom/wiki/0-Installation)
    -   [Easy Install](#installation)
    -   [Manual Install](https://github.com/pry0cc/axiom/wiki/0-Installation#Manual)
-   [Scan Modules](https://github.com/pry0cc/axiom/wiki/Scans#example-axiom-scan-modules)
-   [Contributors](#contributors)

## $100 Free Credit
The original and best supported provider for Axiom is Digital Ocean! If you're signing up for a new Digital Ocean account, [please use my link!](https://m.do.co/c/bd80643300bd) 

<p align="center">
<a href="https://m.do.co/c/bd80643300bd" target="_blank"> <img src="https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/credit.png" height="42px"/></a>
</p>



## Installation

(You will need curl, which is not installed by default on Ubuntu 20.04, if you get a "command not found" error, run `sudo apt update && sudo apt install curl`)

```
bash <(curl -s https://raw.githubusercontent.com/pry0cc/axiom/master/interact/axiom-configure)
```

If you have any problems with this installer, please refer to [Installation](https://github.com/pry0cc/axiom/wiki/0-Installation).

## Demo
In this demo (sped up out of respect for your time ;) ), we show how easy it is to initialize and ssh into a new instance.

<img src="https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/axiom-init-demo.gif" alt="" height=443 width=666px>



## Support
If you like Axiom and it saves you time, money or just brings you happy feelings, please show your support through sponsorship! Click the little sponsor button in the header and sponsor for as little as $1 per month :)

Or buy me a coffee to keep me powered :)

<a href="https://www.buymeacoffee.com/pry0cc" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-black.png" alt="Buy Me A Coffee" style="height: 5px !important;width: 25px !important;" ></a>
---

# Operating Systems Supported
| OS         | Supported | Tested        |  
|------------|-----------|---------------|
| Ubuntu     |    Yes    | Ubuntu 20.04  |
| MacOS      |    Yes    | MacOS 10.15   |
| Debian     |    Yes    |     No        |
| Arch Linux |    Yes    |     Yes       | 
| Windows    | Partially | WSL w/ Ubuntu |



# Contributors
We've had some really fantastic additions to axiom, great feedback through issues, and perseverence through our heavy beta phase!

A list of all contributors can be found [here](https://github.com/pry0cc/axiom/graphs/contributors), thank you all!

## Logo
The logo was made by our amazing [s0md3v](https://twitter.com/s0md3v)! Thank you for making axiom look sleek as hell! Really beats my homegrown logo :)

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

And many more! Do you want to add a package to axiom? [Let me know!](https://github.com/pry0cc/axiom/issues)
