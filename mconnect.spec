# git SHA1 of usable master
%global commit 3cb70f54f3f185d063625ba91609766a92b4cf87
%global shortcommit %(c=%{commit}; echo ${c:0:7})
%global owner bboozzoo

Name:           mconnect
Version:        0.1
Release:        1.20150118git%{shortcommit}%{?dist}
Summary:        Implementation of KDE Connect protocol

License:        GPLv2
URL:            http://github.com/bboozzoo/mconnect
#Source0:        https://github.com/%{owner}/%{name}/archive/%{commit}/%{name}-%{commit}.tar.gz
Source:         %{name}-%{commit}.tar.gz

BuildRequires:  vala
BuildRequires:  glib2-devel
BuildRequires:  json-glib-devel
BuildRequires:  libgee-devel
BuildRequires:  openssl-devel
BuildRequires:  vala-devel
BuildRequires:  libnotify-devel
BuildRequires:  desktop-file-utils

%description

MConnect is an implementation of host side of KDE Connect protocol,
but without any KDE or Qt dependencies.

%prep
%setup -q -D -n %{name}-%{commit}


%build
autoreconf -if
%configure
make %{?_smp_mflags} V=1


%install
%make_install
desktop-file-validate %{buildroot}/%{_datadir}/applications/mconnect.desktop

%files
%doc LICENSE
%{_bindir}/mconnect
%{_datadir}/applications/*.desktop


%changelog
* Sun Jan 18 2015 Maciek Borzecki <maciek.borzecki@gmail.com>
- Initial packaging
