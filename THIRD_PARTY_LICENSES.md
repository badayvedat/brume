# Third-party licenses

Brume ships components of open source projects. Each stays under its own license.

## Components shipped in the app

Fetched at pinned versions by `scripts/setup.sh` and SwiftPM, outside the repository.

| Component | Role | License |
|---|---|---|
| [Ghostty](https://github.com/ghostty-org/ghostty) | Terminal engine (GhosttyKit) | MIT |
| [libghostty-spm](https://github.com/Lakr233/libghostty-spm) | Swift package for the engine, terminal view and themes | MIT |
| [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes) | Color themes, through libghostty-spm | MIT |
| [DisplayLink](https://github.com/Lakr233/DisplayLink) | Dependency of libghostty-spm | MIT |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Suggestions from history | MIT |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | Welcome screen of new terminals | MIT |
| [Sparkle](https://github.com/sparkle-project/Sparkle) | Automatic updates | MIT, and the licenses of its own components below |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Command highlighting | BSD 3-Clause |

### MIT License

Applies to the components above under the MIT License, each with its copyright notice:

```
Copyright (c) 2024 Mitchell Hashimoto, Ghostty contributors
Copyright (c) 2026 @Lakr233
Copyright (c) 2011-present Mark Badolato
Copyright (c) 2024 Lakr Aream
Copyright (c) 2013 Thiago de Arruda
Copyright (c) 2016-2021 Eric Freese
Copyright (c) 2021-2023 Linus Dierheimer
Copyright (c) 2022-2026 Carter Li
Copyright (c) 2006-2013 Andy Matuschak.
Copyright (c) 2009-2013 Elgato Systems GmbH.
Copyright (c) 2011-2014 Kornel Lesiński.
Copyright (c) 2015-2017 Mayur Pawashe.
Copyright (c) 2014 C.W. Betts.
Copyright (c) 2014 Petroules Corporation.
Copyright (c) 2014 Big Nerd Ranch.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### BSD 3-Clause License (zsh-syntax-highlighting)

```
Copyright (c) 2010-2020 zsh-syntax-highlighting contributors
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted
provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this list of conditions
   and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
   conditions and the following disclaimer in the documentation and/or other materials provided
   with the distribution.
 * Neither the name of the zsh-syntax-highlighting contributors nor the names of its contributors
   may be used to endorse or promote products derived from this software without specific prior
   written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

### Components of Sparkle

As listed in the "External licenses" of Sparkle's own license.

bspatch.c and bsdiff.c, from [bsdiff 4.3](http://www.daemonology.net/bsdiff/), and SUSignatureVerifier.m, each under this BSD 2-Clause License with its copyright notice:

```
Copyright 2003-2005 Colin Percival
Copyright (c) 2011 Mark Hamlin.
All rights reserved

Redistribution and use in source and binary forms, with or without
modification, are permitted providing that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
```

sais.c and sais.h, from [sais-lite](https://sites.google.com/site/yuta256/sais) (2010/08/07), under the MIT License above:

```
Copyright (c) 2008-2010 Yuta Mori All Rights Reserved.
```

The portable C implementation of [Ed25519](https://github.com/orlp/ed25519), under the zlib License:

```
Copyright (c) 2015 Orson Peters <orsonpeters@gmail.com>

This software is provided 'as-is', without any express or implied warranty. In no event will the
authors be held liable for any damages arising from the use of this software.

Permission is granted to anyone to use this software for any purpose, including commercial
applications, and to alter it and redistribute it freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not claim that you wrote the
   original software. If you use this software in a product, an acknowledgment in the product
   documentation would be appreciated but is not required.

2. Altered source versions must be plainly marked as such, and must not be misrepresented as
   being the original software.

3. This notice may not be removed or altered from any source distribution.
```

## Fonts

In `Resources/Fonts`, each with its license file next to it.

| Font | License |
|---|---|
| Cascadia Code, Fira Code, Geist Mono, IBM Plex Mono, Inconsolata, JetBrains Mono, Roboto Mono, Source Code Pro, Space Mono | SIL Open Font License 1.1 |
| Ubuntu Mono | Ubuntu Font Licence 1.0 |
