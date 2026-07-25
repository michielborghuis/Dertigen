# Dertigen Teller

Een eenvoudige Flutter-app om scores bij te houden voor het drankspel Dertigen.

## Functies

- Zelf spelers toevoegen, wijzigen en verwijderen
- Per speler: `+1`, `+10` en `−15`
- Bij `−15` gaat de slokkenteller met één omhoog
- Automatisch opslaan
- Nieuw spel zonder spelers te verwijderen
- Undo voor de laatste actie
- Werkt offline

## Vanaf een Android-telefoon bouwen

1. Maak op GitHub een nieuwe repository, bijvoorbeeld `dertigen-teller`.
2. Pak dit ZIP-bestand uit op je telefoon.
3. Upload **alle bestanden en mappen** naar de repository. Vergeet de verborgen map `.github` niet.
4. Open in GitHub de tab **Actions**.
5. Open **Bouw Android APK** en druk op **Run workflow**.  
   Bij de eerste upload kan de workflow ook automatisch beginnen.
6. Wacht tot het groene vinkje verschijnt.
7. Open de geslaagde workflow-run.
8. Download onder **Artifacts** het bestand **Dertigen-Teller-APK**.
9. Pak die download uit en tik op `app-release.apk`.
10. Sta zo nodig installatie uit deze bron toe.

GitHub levert het artifact als ZIP. Daarin staat de echte APK.

## Versie 1.1

- 1–2 spelers: één kolom
- 3–4 spelers: raster met twee kolommen
- 5–9 spelers: raster met drie kolommen
- Tot en met negen spelers probeert de app iedereen zonder scrollen te tonen
- Vanaf tien spelers blijft het raster drie kolommen breed en kun je verticaal scrollen


## Versie 1.2
- App-icoon wordt nu automatisch gegenereerd uit assets/icon/logo.png tijdens de GitHub-build.
