Ubuntu 18.04 

### Prerequisites

- Git
- GCC/G++:
- Make
- curl _(for choosenim)_
- CMake _(for BLS)_
- autoconf / automake / libtool _(for Minisketch)_
- GTK+ 3 and WebKit _(for the GUI)_
- Python 3.6 and Pip _(for the tests)_
- choosenim
- Nim 1.0.4

### Installing prerequisites 


```
sudo apt-get update
```


To install every prerequisite, run:

```
sudo apt-get install git gcc g++ make cmake autoconf automake libtool gtk+-3.0 at-spi2-core webkit2gtk-4.0 curl python3 python3-pip
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
```

Place the following line in the ~/.profile or ~/.bashrc file.
```
echo 'export PATH=/home/ubuntu/.nimble/bin:$PATH' >>~/.profile
source ~/.profile
choosenim 1.0.4
```

You will have to update your path, as according to choosenim, before running any Nim-related commands.

### Meros

#### Build

```
git clone https://github.com/MerosCrypto/Meros.git
cd Meros
```

You can install a headless version which doesn't import any GUI files available via adding `-d:nogui` to the build command.

```
nimble build -d:nogui
```

#### Run

```
./build/Meros
```
