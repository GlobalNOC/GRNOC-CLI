Name: perl-GRNOC-CLI
Version: 1.0.2
Release: 2%{?dist}
Summary: GRNOC CLI utility library
License: GRNOC
Group: Development/Libraries
URL: http://globalnoc.iu.edu
Source0: GRNOC-CLI-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: noarch
Requires: perl >= 5.8.8
Requires: perl-Term-ProgressBar
Requires: perl-TermReadKey

%description
The GRNOC::CLI library is a set of standardized actions that are common in CLI scripts.

%prep
%setup -q -n GRNOC-CLI-%{version}

%build
%{__perl} Makefile.PL PREFIX="%{buildroot}%{_prefix}" INSTALLDIRS="vendor"
make

%install
rm -rf $RPM_BUILD_ROOT
make pure_install

# clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

%{_fixperms} $RPM_BUILD_ROOT/*

%check
make test

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%{perl_vendorlib}/GRNOC/CLI.pm

%doc %{_mandir}/man3/GRNOC::CLI.3pm.gz

%changelog
* Sat Mar  2 2013 Dan Doyle <daldoyle@daldoyle-dev.ctc.grnoc.iu.edu> - GRNOC-CLI
- Initial build.

