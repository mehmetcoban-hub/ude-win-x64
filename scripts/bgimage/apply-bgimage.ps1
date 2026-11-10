# apply-bgimage.ps1 - sayfa arka plan resmi (antet) onbellekli cizim: antetli belgede her boyamada bicubic yavasligi (BGIMG, Mac portu)
param([Parameter(Mandatory)][string]$Jar)
. "$PSScriptRoot\..\common.ps1"
$JavassistVer='3.30.2-GA'; $JavassistUrl="https://repo1.maven.org/maven2/org/javassist/javassist/$JavassistVer/javassist-$JavassistVer.jar"
function Get-Javassist { $lib=Join-Path $VendorDir 'lib'; New-Dir $lib; $jvs=Join-Path $lib "javassist-$JavassistVer.jar"
  if (-not (Test-Path $jvs)) { & curl.exe -L -s -o $jvs $JavassistUrl; if ($LASTEXITCODE -ne 0) { throw "javassist indirilemedi" } }; return $jvs }
$jdk=Get-Jdk11Home; if (-not $jdk) { throw "JDK 11 yok" }
$javac=Join-Path $jdk 'bin\javac.exe'; $java=Join-Path $jdk 'bin\java.exe'; $jarTool=Join-Path $jdk 'bin\jar.exe'; $jvs=Get-Javassist; $dir=$PSScriptRoot
$work=Join-Path $BuildDir '_bgimage'; $helper=Join-Path $work 'helper'; $out=Join-Path $work 'out'
if (Test-Path $work){Remove-Item $work -Recurse -Force}; New-Dir $helper; New-Dir $out
Write-Ok "BgPaint derleniyor"
& $javac --release 11 -encoding UTF-8 -nowarn -d $helper (Join-Path $dir 'macosbgimage\BgPaint.java')
if ($LASTEXITCODE -ne 0) { throw "BgPaint derlenemedi" }
Write-Ok "BgImagePatch derleniyor + calistiriliyor"
& $javac --release 11 -encoding UTF-8 -cp "$jvs" -d $work (Join-Path $dir 'BgImagePatch.java')
if ($LASTEXITCODE -ne 0) { throw "BgImagePatch derlenemedi" }
# Yardimci jar'a patcher BASARILI olduktan sonra yazilir (yarim yama kalmasin);
# patcher BgPaint'i sinif yolundaki $helper dizininden cozer.
& $java -cp "$work;$jvs;$helper" BgImagePatch $Jar $out
if ($LASTEXITCODE -eq 3) {
  # Hedef cagri bulunamadi/coklu: jar'a dokunulmadi. Arka plan resmi stok (hizli, en yakin
  # komsu) cizilir; bu bir hiz iyilestirmesi oldugundan build'i durdurma.
  Write-Warn2 "BGIMG atlandi: at icindeki drawImage cagrisi beklenen bicimde degil (UDE surumu degismis olabilir)"
  return
}
if ($LASTEXITCODE -ne 0) { throw "BgImagePatch calismadi" }
if (Test-Path (Join-Path $out 'tr')) {
  & $jarTool uf $Jar -C $helper .
  if ($LASTEXITCODE -ne 0) { throw "BgPaint jar'a eklenemedi" }
  & $jarTool uf $Jar -C $out .
  if ($LASTEXITCODE -ne 0) { throw "yamali sinif eklenemedi" }
  Write-Ok "BGIMG (arka plan resmi onbellekli cizim) uygulandi"
} else {
  Write-Ok "BGIMG zaten yamali, atlandi"
}
