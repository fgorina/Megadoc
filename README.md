#  Megadoc - Una aplicació segura per documents confidencials
Ja fa uns mesos que la llibertat d'expressió està molt amenaçada a Catalunya i també a Espanya, amb compareixences judicials, registres policíacs i denuncies per *incitació a l'odi* i coses semblants.

A mes, el 1-O es van produir cyberatacs a webs que defenien o servien de infraestructura per el Referèndum que va ser reprimit amb violència per les forces d'ocupació (perdo de l'Ordre Públic)

## [![VIDEOS VIOLÈNCIA POLICIA](http://img.youtube.com/vi/bBUJNbLa4ko/1.jpg)](http://www.youtube.com/watch?v=bBUJNbLa4ko)

Es força increïble que això passi al 2017 a un país membre de la Unió Europea i amb el seu beneplàcit. Els Xinesos estan encantats doncs ara serà difícil per la [UE criticar les seves actuacions al Tibet](http://www.elnacional.cat/ca/politica/xina-catalunya-ue_214644_102.html).

En aquestes circumstàncies i amb un sistema judicial amb criteris ben diferents segons la teva ideologia es important tenir els documents mes personals, que registren els nostres pensaments, les nostres idees, a prova de autoritats escoltapets.

Per això us proposo aquesta senzilla aplicació per a iOS. Us permet tenir els documents **markdown** que vulgueu, convenientment encriptats.

A mes, no us cal sortir de l'aplicació que incorpora un editor i un preview dels documents.

Aquests poden guardar-se localment, al iCloud, a Google Drive, etc i segueixen estan protegits per un AES256 i un RSA dels bits que vulgueu però posats a fer poseu quelcom com 4096 que estareu mes tranquils.

La aplicació fa servir la clau pública i privada que s'han de generar de forma externa. Aquí teniu un exemple de com fer-ho amb openssl :

```
openssl genrsa -out private.pem 4096
openssl rsa -in private.pem -pubout -outform PEM -out public.pem
```

Necessitem els arxius en format **.pem**.

Aleshores hem de moure aquests arxius al directori corresponent a la Megadoc a dispositiu. Ho podeu fer tranquil·lament amb l'aplicació de Apple *Arxius* . Heu de moure els arxius .pem a algun lloc accessible per arxius i després els seleccioneu, feu *traslladar* i seleccioneu al dispositiu l'aplicació **Megadoc**.

Quan torneu a arrencar **Megadoc** o be us identifiqueu els assegurarà amb la vostre contrasenya i els guardarà.

Els arxius originals que teniu son una copia de les claus i si cauen en males mans permetrien obrir tot els vostres arxius. Les copieu a un pen drive o similar i les envieu a un amic ben llunya i sobretot elimineu-les dels vostres dispositius en que les heu generat o traspassat. L'idea es que no siguin enlloc.

Mes endavant us explico com fer copies de les claus encriptades que es quelcom mes segur.

La aplicació es una mica neuròtica i al cap de uns 30'' sense treballar tanca la pantalla però la podeu reobrir amb el dit.

Si tanqueu amb el candau aleshores necessitareu el password i teniu tan sols 3 intents. Desprès esborra les claus. Es fàcil equivocar-se quan estas nerviós i tens un policia intentant que desbloque-ixis les dades.

Si mireu be veureu que hi ha un dibuix com un interruptor. Es l'interruptor de pànic i serveix per esborrar les claus directament.

Penseu que una vegada esborrades les claus NO es pot accedir al contingut dels documents. O sigui que ningú podrà saber que hi ha a dintre però vosaltres tampoc.

Depenent de l'arriscat de la vostre situació haureu de prendre unes mesures o altres.

## Exportant les claus encriptades

Es tan senzill com fer click a la clau i apareixeran les claus com arxius .enc al directori de documents de la aplicaciò al nostre dispositiu. Les podreu moure amb *Arxius* a on vulgeu i esborrar-les del dispositiu. No patiu, les de veritat son amagades.

## Pànic

Si no tenim mes remei que bloqueixarho tot podem fer servir el botó de *pànic* i respondre sí. S'esborraran les claus i els arxius quedaràn inutilitzables.

## Compartint

Podem compartir desde el File Browser però recordeu que compartireu un document encriptat. Si les envieu a un amic aquest no podrà llegir el document.

Si en canvi els compartiu desde dintre el document enviareu el fitxer desencriptat. Si es lo que voleu endavant!!! però penseu que la major part de sistemes de comunicació per Internet com el correu no son segurs.

En una propera versiò mioraré de incorporar claus de corresponsals per poder enviar mes fàcilment els documents.

## Sigueu curosos
Finalment recordeu que millor fer servir una VPN fiable per assegurar les vostres comunicacions. Desprès que els Operadors van col·laborar amb l’Estat per impedir el 1-O millor que no sàpiguen que passa per els seus tubs. Avui mateix llegeixo [El 155 vigila els mòbils i els mails dels treballadors públics](http://elmon.cat/politica/155-vigila-mobils-mails-dels-treballadors-publics) o sigui que atenció que mai se sap.

## Disclaimer

Aquest programa es dona com es. No em puc fer responsable del seu us ni de que la seva funcionalitat no sigui suficient.

Es posa en **open source** per que aquells que vulguin puguin col·laborar a validar la seva seguretat.

## Llicència

El codi font i el programa son de lliure utilització per qualsevol membre o simpatitzant de la Assemblea Nacional Catalana, Omnium Cultural, CDR’s o individus particulars.

Altres col·lectius haurien de demanar permís a l’autor que decidirà en funció de una funció de aleatòria de prou qualitat.

Gàngsters i terroristes abstenir-se.

## Agraïments

Aquesta aplicació fa servir les següents llibreries. Molt agraït als seus desenvolupadors que han fet una gran feina simplificant aquest tipus d'aplicació. Mireu les seves llicències si son d’aplicació.

- [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) es una llibreria de funcions de encripció. Es fa servir fonamentalment per l’algoritme AES.
- [SwiftyRSA](https://github.com/TakeScoop/SwiftyRSA) es una llibreria per fer la encripció, desencripció amb l’algoritme RSA de clau pública / privada.
- [Down](https://github.com/iwasrobbed/Down) es una llibreria que fa una conversió de **markdown** a **html** per visualitzar millor la documentació.
- [Cocoapods](https://cocoapods.org) es el sistema de integració d’aquestes llibreries a Megadoc.

