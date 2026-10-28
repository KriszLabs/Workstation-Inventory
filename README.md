# Workstation Inventory

Egyetlen fájlból álló Windows batch script, amely a futtatás pillanatában lekérdezi a munkaállomás legfontosabb hardveres, operációs rendszeres és hálózati adatait, és a konzolon megjeleníti őket. Nem telepít semmit, nem ír fájlt és nem módosít rendszerbeállítást.

![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue)
![Shell](https://img.shields.io/badge/shell-cmd%20%2B%20PowerShell%205.1-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

## Tartalom

- [Funkciók](#funkciók),
- [Követelmények](#követelmények),
- [Használat](#használat),
- [Példakimenet](#példakimenet),
- [Működés](#működés),
- [Testreszabás](#testreszabás),
- [Ismert korlátok](#ismert-korlátok),
- [Hozzájárulás](#hozzájárulás),
- [Licenc](#licenc).

## Funkciók

| Csoport | Adatok 
|---|---|---|
| Alapadatok | Gépnév, felhasználó (`DOMAIN\user`), domain / munkacsoport |
| Hardver | Gyártó, modell, sorozatszám, BIOS verzió és dátum, CPU, magok / szálak, RAM, videókártya(k), lemezek (szabad/összes GB) |
| Operációs rendszer | Kiadás, verzió és build, architektúra, telepítés dátuma, utolsó indítás, üzemidő |
| Hálózat | Aktív adapter, IPv4 cím, MAC cím, alapértelmezett átjáró, DNS szerverek |

Jellemzők:

- **Nincs kimeneti fájl**, az eredmény csak a konzolra kerül.
- **Nem igényel rendszergazdai jogot** (a használt lekérdezések alapesetben olvashatók felhasználóként).
- **Egy PowerShell-hívás** gyűjti az összes adatot, ezért gyors.
- **Hibatűrő**: ha egy adat nem érhető el, `N/A` vagy `Ismeretlen` jelenik meg, a többi mező nem csúszik el.

## Követelmények

- Windows 10 / 11
- Windows PowerShell 5.1
- Szükséges parancsok: `Get-CimInstance`, `Get-NetIPConfiguration`, `Get-NetAdapter`

## Használat

1. Töltsd le a `Workstation_Inventory.bat` fájlt.
2. Futtasd dupla kattintással, vagy parancssorból:

   ```bat
   Workstation_Inventory.bat
   ```

3. A futás végén egy billentyű lenyomásával bezárható az ablak.

Távoli vagy csoportházirenddel korlátozott gépen előfordulhat, hogy a PowerShell futtatása tiltott. 
Ilyenkor lásd a [Hibaelhárítás](#hibaelhárítás) részt.

## Példakimenet

(A lenti értékek kitalált példák.)

```text
========================================
     WORKSTATION INVENTORY v1.1
========================================
Futtatás ideje: 2026. 10. 28. 14:30:12,45

[ALAPINFORMÁCIÓK]
  Gépnév:               PC-EXAMPLE01
  Felhasználó:          CONTOSO\janos.kovacs
  Domain/Munkacsoport:  WORKSPACE

[HARDVER]
  Gyártó:               Dell Inc.
  Modell:               OptiPlex 7090
  Sorozatszám:          ABC1234
  BIOS verzió:          1.15.0 (2023-05-10)
  Processzor:           Intel(R) Core(TM) i7-10700 CPU @ 2.90GHz
  Magok / szálak:       8 / 16
  Memória:              32 GB
  Videókártya:          Intel(R) UHD Graphics 630
  Lemezek (szabad/össz): C: 210/476 GB

[OPERÁCIÓS RENDSZER]
  Rendszer:             Microsoft Windows 11 Pro
  Verzió:               10.0.22631 (build 22631)
  Architektúra:         64 bites
  Telepítés dátuma:     2025-03-14
  Utolsó indítás:       2026-10-27 08:12
  Üzemidő:              30 óra

[HÁLÓZAT]
  Aktív adapter:        Ethernet
  IPv4 cím:             192.168.1.50
  MAC cím:              AA-BB-CC-DD-EE-FF
  Alapértelmezett GW:   192.168.1.1
  DNS szerverek:        192.168.1.10, 192.168.1.11
========================================
```

## Működés

1. **PowerShell-parancs összeállítása.** A script `set "PS=%PS%..."` sorokkal építi fel a parancsot egy változóba. Ez olvashatóbb, mint egyetlen hosszú sor, és nem használ `^` sortöréseket.
3. **Kulcs-érték kimenet.** A PowerShell egy `o` nevű segédfüggvénnyel `INV_KULCS=érték` sorokat ír. Ha az érték üres, a függvény `N/A`-t ír, így a kimenet sorszáma mindig állandó.
4. **Beolvasás.** A `for /f` ciklus `=` mentén szétbontja a sorokat, és `INV_*` nevű környezeti változókat hoz létre. Az `INV_` előtag megakadályozza, hogy a változók ütközzenek a rendszer változóival (pl. `OS`, `PROCESSOR_*`).
5. **Alapértékek.** Ha egy változó mégsem jön létre (például a PowerShell nem futott le), `Ismeretlen` kerül a helyére.
6. **Kiírás.** A megjelenítés késleltetett kiterjesztéssel (`!VAR!`) történik, így az értékekben szereplő speciális karakterek (pl. `&`) nem törik meg a `echo` parancsot.

A hálózati blokk az alapértelmezett átjáróval rendelkező adaptert használja, ezért a virtuális adapterek (VPN, Hyper-V, WSL) nem zavarják a kimenetet.

## Testreszabás

**Új adat hozzáadása.** Vegyél fel egy új `set "PS=%PS%o 'KULCS' <kifejezés>;"` sort, majd:

1. add hozzá a kulcsot a `for %%V in (...)` listához az alapértékekhez,
2. írd ki a `!INV_KULCS!` változót a kiírási részben.

Példa, az időzóna kiírása:

```bat
set "PS=%PS%o 'TIMEZONE' (Get-TimeZone).Id;"
```

Ezután a `for %%V in (...)` listába vedd fel a `TIMEZONE` kulcsot, a kiírásba pedig az `echo   Időzóna:  !INV_TIMEZONE!` sort.

Megjegyzés: a PowerShell-kód a batchben dupla idézőjelek közt fut, ezért PowerShell oldalon kizárólag egyszeres idézőjelet használj, és kerüld a `%`, `!`, `^` karaktereket (vagy duplázd/escape-eld őket).

**Kimenet fájlba irányítása.** A script szándékosan nem ment fájlt. Ha mégis kell, futtasd így:

```bat
Workstation_Inventory.bat > inventory.txt
```

## Ismert korlátok

- Csak egy aktív (átjáróval rendelkező) hálózati adaptert jelenít meg. 
- Ha az érték `!` karaktert tartalmaz, a késleltetett kiterjesztés miatt az eltűnhet. 
- A `%date%` és `%time%` formátuma a területi beállítástól függ. 
- Windows 7 és régebbi rendszereken nem támogatott.
- Nincs `.ps1` verzió, a script CMD-ben fut és PowerShellt hív le. 

## Hozzájárulás

Hibajelentést és javaslatot Issue-ban várok. 
Pull request esetén:

- Tartsd a `.bat` fájlt UTF-8, CRLF sorvéggel.
- Új adat esetén frissítsd a README funkciótáblázatát és a `CHANGELOG.md` fájlt.
- A PR leírásában add meg, melyik Windows-verzión próbáltad ki.
- Kérlek mindent dokumontálj.

## Licenc
[MIT](LICENSE)

## Állapot 
- Utolsó frissítés: 2026. 10. 28.
