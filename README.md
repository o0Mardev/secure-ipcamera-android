# secure-ipcamera-android
Trasforma un telefono Android con root in una IP camera sicura e accessibile via VPN, usando Termux, OpenVPN e IP Webcam.


Hai un vecchio telefono Android a prendere polvere in un cassetto? In questa guida ti mostro come trasformarlo in una IP Webcam sicura e accessibile da remoto, sfruttando i permessi di root.

![Platform](https://img.shields.io/badge/platform-android-green)
![Root Required](https://img.shields.io/badge/root-required-critical)

## Indice

- [Il progetto](#il-progetto)
- [Come fare](#come-fare)
- [Script utili](#script-utili)


## Il progetto
L’obiettivo è riutilizzare un vecchio smartphone Android come webcam accessibile da qualsiasi parte del mondo, in modo sicuro grazie a una connessione VPN. 
Il telefono trasmette il video sulla rete locale tramite un’app dedicata, nel mentre un server VPN (installato sempre sul telefono) permette l’accesso remoto protetto. In pratica:

- Lo smartphone diventa una webcam IP grazie all'app *IP Webcam*.

- Con i permessi di root (ottenuti tramite Magisk), viene installato e configurato *OpenVPN* tramite Termux.

- Il telefono si trasforma in un server VPN.

- Aprendo una porta sul proprio router, puoi collegarti da remoto in sicurezza al tuo telefono e vedere il flusso video.

## Come fare
Come prima cosa puoi copiare la repo, contiene alcuni script utili
```
git clone https://github.com/o0Mardev/Secure-ipcam-android.git
cd secure-ipcam-android
```
> Assicurati di rendere eseguibili gli script che useremo più avanti:
> ```
> chmod +x scripts/*.sh
> ```

1. Installa [Magisk](https://github.com/topjohnwu/Magisk) per i permessi di root
2. Installa [Termux](https://github.com/termux/termux-app)
3. Da Termux, per installare e configurare OpenVPN:
    - Per prima cosa eseguire questi comandi per installare il pacchetto:
        ```
        pkg install root-repo
        pkg update
        pkg install openvpn
        ``` 
    -  Ora è necessario generare i certificati e le chiavi \
        Installa [easy-rsa](https://github.com/OpenVPN/easy-rsa), per semplificare l'installazione su Termux, puoi usare lo script incluso in questa repo:
        ```
        ./scripts/install-easyrsa.sh
        ```
        Ora da dentro la cartella easy-rsa puoi eseguire i seguenti comandi:
        ```
        ./easyrsa init-pki
        ./easyrsa build-ca
        ./easyrsa gen-dh
        ./easyrsa build-server-full server nopass
        ./easyrsa build-client-full client nopass
        ```
    - Crea il file `server.conf` nella tua home directory, puoi usare l'editor che preferisci (come vim, nano), trovi un esempio simile nella cartella *configs*.
        > Cambia il path dei certificati e delle chiavi se diverso! 
        > <br>Sperimenta con le varie impostazioni [qua](https://github.com/OpenVPN/openvpn/tree/master/sample/sample-config-files) degli esempi
        ```
        port 1194
        proto udp
        dev tun
        tun-mtu 1360
        server 10.8.0.0 255.255.255.0
        topology subnet

        ca /data/data/com.termux/files/home/easy-rsa/pki/ca.crt  
        cert /data/data/com.termux/files/home/easy-rsa/pki/issued/server.crt
        key /data/data/com.termux/files/home/easy-rsa/pki/private/server.key
        dh /data/data/com.termux/files/home/easy-rsa/pki/dh.pem

        keepalive 10 120
        push "route 10.8.0.0 255.255.255.0"
        cipher AES-256-CBC

        user nobody
        group nobody

        persist-key
        persist-tun

        client-to-client

        ifconfig-pool-persist ipp.txt
        status openvpn-status.log
        verb 3
        ```
        
    - Apri la porta del tuo router

        Accedi nella pagina di configurazione del tuo router (di solito alla pagina 192.168.1.1), imposta un IP statico al telefono e apri la porta "1194", come protocollo scegli UDP.
        > Se non possiedi un IP statico (o il tuo ISP non te lo fornisce), ti consiglio di utilizzare un servizio *DDNS (Dynamic DNS)* come [No-IP](https://www.noip.com/it-IT) o [Dynu](https://www.dynu.com/) per mantenere sempre raggiungibile il tuo dispositivo anche se il tuo indirizzo IP cambia.


    - Configurare il client

        Su un altro dispositivo installare l'app di [OpenVPN](https://openvpn.net/client/) ora bisogna creare il file di configurazione per il client. \
        Crea quindi un file `client.ovpn` effettuando le modifiche indicate, trovi un esempio simile nella cartella *configs*.

        ```
        client
        dev tun
        proto udp
        remote *INSERISCI indirizzo ip statico o url del servizio DDNS* 1194
        resolv-retry infinite
        nobind
        persist-key
        persist-tun
        <ca>
        -----BEGIN CERTIFICATE-----
        COPIA IL CONTENUTO DI /easy-rsa/pki/ca.crt
        -----END CERTIFICATE-----
        </ca>

        <cert>
        -----BEGIN CERTIFICATE-----
        COPIA IL CONTENUTO DI /easy-rsa/pki/client.crt
        -----END CERTIFICATE-----
        </cert>

        <key>
        -----BEGIN PRIVATE KEY-----
            COPIA IL CONTENUTO DI /easy-rsa/pki/private/client.key
        -----END PRIVATE KEY-----
        </key>

        cipher AES-256-CBC
        verb 3
        ```

        File fatto, ora dall'App di OpenVPN puoi importare il file di configurazione.

        Da termux sul telefono che fa da server VPN:
        ```
        pkg install tsu
        ```
        Serve per eseguire comandi come root tramite tsu, un'alternativa a sudo per Termux.
        Ora puoi avviare il server VPN.
        ```
        sudo openvpn --config server.conf
        ```

        Infine dal client puoi attivare la connessione. Per verificare che sia accessibile anche al di fuori della tua rete locale prova a collegarti utilizzando la rete mobile.

        Il peggio è passato. Il server VPN è stato configurato e siamo riusciti a collegarci da remoto.

4. Installare l'app [IP webcam](https://play.google.com/store/apps/details?id=com.pas.webcam)
    - Apri l'app, tre puntini -> "Avvio del server", concedi i permessi necessari.
    - L'app IP Webcam è attiva ma accessibile solo nella rete locale. Per renderla accessibile da remoto tramite VPN, servono alcune regole di routing.

    Dopo aver avviato il server di OpenVPN puoi lanciare i seguenti comandi:
    ```
    sudo ip rule add from 10.8.0.0/24 table 10
    sudo ip route add 10.8.0.0/24 dev tun0 table 10
    ```
    - Una volta fatto tutto ciò potrai collegarti da remoto

5. Ora puoi attivare la connessione VPN tramite l'app di OpenVPN dal tuo client e dal browser collegarti all'indirizzo **10.8.0.1:8080**


## Script utili

Nella repo sono presenti alcuni script utili per avviare rapidamente il server VPN e l'app di IP webcam:

- "start_vpn_server.sh" \
    Avvia il server VPN in background e imposta le regole di routing.

- "start_ipcam.sh" \
    Lancia l'app IP Webcam e spegne lo schermo dopo qualche secondo per risparmiare batteria.

- "stop_vpn_server.sh" \
    Interrompe il processo OpenVPN. 

- "stop_ipcam.sh" \
    Termina l'app IP Webcam.

> [!NOTE]
> Con questo setup puoi anche impostare un webserver accessibile da remoto!
> Ad esempio puoi configurare *apache*, *php*, *mariaDB* e *PhpMyAdmin*
