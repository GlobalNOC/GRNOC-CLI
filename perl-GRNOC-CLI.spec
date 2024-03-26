%global debug_package %{nil} # Don't generate debug info
%define perl_lib /opt/grnoc/venv/
%define specfile_deps %(cat cpanfile | sed -r 's/^requires ([^[:space:]]*)/Requires: perl(\\1)/' | sed 's/["'"'"';]//g')
AutoReqProv: no # Keep rpmbuild from trying to figure out Perl on its own
Name: perl-GRNOC-CLI
Version: 1.0.3
Release: 1%{?dist}
Summary: GRNOC CLI utility library
License: GRNOC
Group: Development/Libraries
URL: http://globalnoc.iu.edu
Source0: GRNOC-CLI-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
%if 0%{rhel} == 8
BuildArch: x86_64
%else
BuildArch: noarch
%endif
Requires: perl >= 5.8.8
%if 0%{?rhel} == 7
%{specfile_deps}
%endif

%description
The GRNOC::CLI library is a set of standardized actions that are common in CLI scripts.

%prep
%setup -q -n GRNOC-CLI-%{version}

%build
%{__perl} Makefile.PL PREFIX="%{buildroot}%{_prefix}" INSTALLDIRS="vendor"
make

%install
%if 0%{rhel} == 8
%{__install} -d -p %{buildroot}%{perl_lib}%{name}/lib/perl5
cp -r venv/lib/perl5/* -t %{buildroot}%{perl_lib}%{name}/lib/perl5
%endif
# rm -rf $RPM_BUILD_ROOT
make pure_install

# clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

%{_fixperms} $RPM_BUILD_ROOT/*

%check
make test

%clean
rm -rf $RPM_BUILD_ROOT


%files
%if %{rhel} == 8
%{perl_lib}/%{name}/lib/perl5/*
%endif
%defattr(-,root,root,-)
%{perl_vendorlib}/GRNOC/CLI.pm

%doc %{_mandir}/man3/GRNOC::CLI.3pm.gz

%changelog
* Sat Mar  2 2013 Dan Doyle <daldoyle@daldoyle-dev.ctc.grnoc.iu.edu> - GRNOC-CLI
- Initial build.

