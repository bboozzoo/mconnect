# git SHA1 of usable master
%global commit b8ffa0fe6e9624b00c4d6523ec58da8d70404717
%global shortcommit %(c=%{commit}; echo ${c:0:7})
%global owner bboozzoo

Name:           mconnect
Version:        0.1
Release:        2.20150119git%{shortcommit}%{?dist}
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
%dir %{_datadir}/mconnect
%{_datadir}/mconnect/*
%{_datadir}/applications/*.desktop

%changelog
* Mon Jan 19 2015 Maciek Borzęcki <maciek.borzecki@gmail.com> - 0.1-2.20150119gitb8ffa0f
- Bump version to include bug fixes

* Sun Jan 18 2015 Maciek Borzecki <maciek.borzecki@gmail.com> - 0.1-1.20150118git55ae51a
- Initial packaging
