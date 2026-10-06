# Company Certificates in WSL

Install a company certificate only if a company service reports a TLS or certificate trust error. Get the certificate from your IT or security team. Do not turn off certificate checks.

These steps are for Ubuntu and other Debian-based distributions. Ask IT for a PEM-encoded `.crt` file.

## Add the Certificate

Copy the approved certificate into Ubuntu's local certificate folder. Replace the Windows user and file name with your own:

```bash
sudo cp "/mnt/c/Users/<WindowsUser>/Downloads/company-root.crt" /usr/local/share/ca-certificates/company-root.crt
sudo update-ca-certificates
```

Check access to the approved company service:

```bash
curl -I "https://<company-service>"
```

## If Node.js Still Reports a Certificate Error

Some Node.js tools need the certificate file named explicitly:

```bash
export NODE_EXTRA_CA_CERTS="/usr/local/share/ca-certificates/company-root.crt"
```

Start the affected tool from that shell. Ask IT for help if it still fails. Never use `NODE_TLS_REJECT_UNAUTHORIZED=0`; it turns off TLS certificate checks.

## Related

- [Networking](./NETWORKING.md)
- [WSL troubleshooting](./TROUBLESHOOTING.md)