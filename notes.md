# Notes on setting up bluetooth keyboard

```
sudo apt install bluetooth bluez-tools
sudo /etc/init.d/bluetooth start
```

Edit `/etc/default/bluetooth` set `HID2HCI_ENABLED=1`

```bash
sudo /etc/init.d/bluetooth restart
sudo hciconfig hci0 up
sudo hcitool scan

sudo bluetoothctl

[bluetooth]# scan on
[bluetooth]# info 34:88:5D:7B:CB:78
[bluetooth]# pair 34:88:5D:7B:CB:78
[Keys-To-Go]# trust 34:88:5D:7B:CB:78
[bluetooth]# scan off
[bluetooth]# connect 34:88:5D:7B:CB:78
```
