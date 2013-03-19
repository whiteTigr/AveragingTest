program Averaging;

{$APPTYPE CONSOLE}

uses
  SysUtils, Generics.Collections, Math;

type
  TValueList = TList<integer>;
  PValueList = ^TValueList;

var
  arr: TValueList;

function ReadFile(const fileName: string): TValueList;
var
  inputFile: TextFile;
  Value: TList<integer>;
  int: integer;
  test: TValueList;
begin
  AssignFile(inputFile, fileName);
  Reset(inputFile);
  try
    Result := TValueList.Create;
    Value := TList<integer>.Create;
    Result.Clear;
    while not eof(inputFile) do
    begin
      Value.Clear;
      while not eoln(inputFile) do
      begin
        read(inputFile, int);
        Value.Add(int);
      end;
      readln(inputFile);
      if Value.Count > 9 then
        Result.Add(Value[9]);
    end;
  finally
    CloseFile(inputFile);
    Value.Free;
  end;
end;

procedure WriteFile(const fileName: string; const arr: TValueList);
var
  outputFile: TextFile;
  i: integer;
begin
  AssignFile(outputFile, fileName);
  Rewrite(outputFile);
  try
    for i := 0 to arr.Count - 1 do
      writeln(outputFile, arr[i]);
  finally
    CloseFile(outputFile);
  end;
end;

function NextPoint(index: integer): integer;
var
  baiessArr: array[-65536..65536] of integer;
  i, j: integer;
begin
  for i := -65536 to 65535 do
    baiessArr[i] := 0;

  for j := index-7 to index do
    for i := -500 to 500 do
      inc(baiessArr[arr[j] + i], 500 - abs(i));

  Result := -65536;
  for i := -65535 to 65535 do
    if baiessArr[i] > baiessArr[Result] then
      Result := i;
  Result := baiessArr[Result];
end;

procedure WriteTestFile(const fileName: string);
var
  outputFile: TextFile;
  i: integer;
begin
  AssignFile(outputFile, fileName);
  Rewrite(outputFile);
  try
    for i := 7 to arr.Count - 1 do
      writeln(outputFile, arr[i], #9, NextPoint(i));
  finally
    CloseFile(outputFile);
  end;
end;

function shra(value: integer; shiftCount: integer): integer;
const
  shiftMask: array[0..31] of cardinal =
  ($00000000,
   $80000000, $C0000000, $E0000000, $F0000000,
   $F8000000, $FC000000, $FE000000, $FF000000,
   $FF800000, $FFC00000, $FFE00000, $FFF00000,
   $FFF80000, $FFFC0000, $FFFE0000, $FFFF0000,
   $FFFF8000, $FFFFC000, $FFFFE000, $FFFFF000,
   $FFFFF800, $FFFFFC00, $FFFFFE00, $FFFFFF00,
   $FFFFFF80, $FFFFFFC0, $FFFFFFE0, $FFFFFFF0,
   $FFFFFFF8, $FFFFFFFC, $FFFFFFFE);
begin
  Result := value shr shiftCount;
  {$WARNINGS OFF}
  if (value and $80000000) <> 0 then
    Result := Result or shiftMask[shiftCount and 31];
  {$WARNINGS ON}
end;

procedure CalcAtanTable;
var
  atg: array[0..31] of real;
  i: integer;
begin
  for i := 0 to 31 do
    atg[i] := System.ArcTan(1/Power(2, i)) * 180 / Pi * 1000000;
end;

procedure SinCos(const angle: integer; out cos: integer; out sin: integer);
const
  atg: array[0..26] of integer = (
    45000000 , 26565051 , 14036243 , 7125016 , 3576334 , 1789911 , 895174 , 447614 ,
    223811 , 111906 , 55953 , 27976 , 13988 , 6994 , 3497 , 1749 ,
    874 , 437 , 219 , 109 , 55 , 27 , 14 , 7, 3, 2, 1);
var
  i: integer;
  x, y, z: integer;
  newX, newY: integer;
  xHalf, yHalf: integer;
  power: integer;
begin
  z := angle;
//  x := 900502 shl 10; // 900517
  x := 922113738;
  y := 0;
  for i := 1 to 26 do
  begin
    if z > 0 then
    begin
      z := z - atg[i];
      newX := x - shra(y, i);
      newY := y + shra(x, i);
    end
    else
    begin
      z := z + atg[i];
      newX := x + shra(y, i);
      newY := y - shra(x, i);
    end;
    x := newX;
    y := newY;
  end;
  x := shra(x, 10);
  y := shra(y, 10);
  cos := round(x);
  sin := round(y);
end;

function Sin(angle: integer): integer;
var
  intCos, intSin: integer;
  sign: integer;
begin
  if angle < 0 then
    sign := -1
  else
    sign := 1;
  angle := abs(angle);
  if angle < 45000000 then
  begin
    SinCos(angle, intCos, intSin);
    Exit(intSin * sign);
  end;

  if angle < 90000000 then
  begin
    SinCos(90000000 - angle, intCos, intSin);
    Exit(intCos * sign);
  end;

  if angle < 135000000 then
  begin
    SinCos(angle - 90000000, intCos, intSin);
    Exit(intCos * sign);
  end;

  SinCos(180000000 - angle, intCos, intSin);
  Exit(intSin * sign);
end;

function Cos(angle: integer): integer;
var
  intCos, intSin: integer;
begin
  angle := abs(angle);
  if angle < 45000000 then
  begin
    SinCos(angle, intCos, intSin);
    Exit(intCos);
  end;

  if angle < 90000000 then
  begin
    SinCos(90000000 - angle, intCos, intSin);
    Exit(intSin);
  end;

  if angle < 135000000 then
  begin
    SinCos(angle - 90000000, intCos, intSin);
    Exit(-intSin);
  end;

  SinCos(180000000 - angle, intCos, intSin);
  Exit(-intCos);
end;

function Mul(a, b: integer): integer;
begin
  Result := shra(shra(a, 5) * shra(b, 5), 10);
end;

function Sqrt(value: integer): integer;
var
  mask: integer;
begin
  mask := $100000;
  Result := 0;
  while mask <> 0 do
  begin
    if Mul(Result, Result) < value then
      Result := Result or mask;
    if Mul(Result, Result) > value then
      Result := Result and not mask;
    mask := mask shr 1;
  end;
end;

function CosWithSin(angle: integer): integer;
var
  sinValue: integer;
begin
  sinValue := Sin(angle);
  Result := Sqrt((1 shl 20) - Mul(sinValue, sinValue));
  if angle > 90000000 then
    Result := -Result;
end;

function ACos(value: integer): integer;
const
  AngleTable: array[0..26] of integer = (
    45000000 , 22500000 , 11250000 , 5625000 , 2812500 , 1406250 , 703125 , 351562 , 175781 , 87890 ,
    43945 , 21973 , 10986 , 5493 , 2746 , 1373 , 686 , 343 , 172 , 86 , 43 , 22 , 11 , 5, 3, 2, 1);
var
  i: integer;
begin
  Result := 45000000;
  for i := 1 to 26 do
  begin
    if value <= cos(result) then
      result := result + AngleTable[i]
    else
      result := result - AngleTable[i];
  end;
end;

function ASin(value: integer): integer;
const
  AngleTable: array[0..26] of integer = (
    45000000 , 22500000 , 11250000 , 5625000 , 2812500 , 1406250 , 703125 , 351562 , 175781 , 87890 ,
    43945 , 21973 , 10986 , 5493 , 2746 , 1373 , 686 , 343 , 172 , 86 , 43 , 22 , 11 , 5, 3, 2, 1);
var
  i: integer;
begin
  Result := 45000000;
  for i := 1 to 26 do
  begin
    if value <= sin(result) then
      result := result + AngleTable[i]
    else
      result := result - AngleTable[i];
  end;
end;

function Distance(lat1, lat2, lon1, lon2: integer): integer;
var
  d: integer;
  cos_d: integer;
  sin_d: integer;
  pretc: integer;
  tc: integer;
begin
  cos_d := Mul(sin(lat1), sin(lat2)) + Mul(Mul(cos(lat1), cos(lat2)), cos(lon1 - lon2));
  sin_d := Sqrt(1048576 - Mul(cos_d, cos_d));
  d := acos(d);
  pretc := round((sin(lat2) - sin(lat1) * cos_d)/(sin_d * cos(lat1)));
  tc := 2 * asin(sqrt((1048576 - pretc) div 2));
  if sin(lon1 - lon2) < 0 then
    Result := tc
  else
    Result := 360000000 - tc;
end;

function DistanceEtalon(_lat1, _lat2, _lon1, _lon2: integer): integer;
var
  d, tc: real;
  lat1, lat2, lon1, lon2: real;
begin
  lat1 := DegToRad(_lat1 / 1000000);
  lat2 := DegToRad(_lat2 / 1000000);
  lon1 := DegToRad(_lon1 / 1000000);
  lon2 := DegToRad(_lon2 / 1000000);
  d := Math.arccos(System.sin(lat1) * System.sin(lat2) + System.cos(lat1) * System.cos(lat2) * System.cos(lon1-lon2));
  tc := Math.arccos((System.sin(lat2) - System.sin(lat1) * System.cos(d))/(System.sin(d) * System.cos(lat1)));
  if System.sin(lon1-lon2) < 0 then
    Result := round(tc)
  else
    tc := 2 * pi - round(tc);
end;

procedure SinCosTest;
var
  i: integer;
  intCos, intSin: integer;
  realCos, realSin: real;
  f: TextFile;
begin
  AssignFile(f, 'tmp.txt');
  Rewrite(f);
  for i := 1 to 45000000 do
  begin
    SinCos(i, intCos, intSin);
    realCos := round(System.Cos(i*Pi/180/1E6)*1024*1024);
    realSin := round(System.Sin(i*Pi/180/1E6)*1024*1024);
    if (abs(realCos - intCos) > 31) or (abs(realSin - intSin) > 31) then
      writeln(f, i, #9, trunc(realCos - intCos), #9, trunc(realSin - intSin));
  end;
  CloseFile(f);
end;

procedure CosTest;
var
  i, j: integer;
  intCos, intSin: integer;
  realCos, realSin: real;
  f: TextFile;
  errF: TextFile;
  error: integer;
  errors: array[-32..32] of integer;
  allErrors: array[-32..32] of integer;
begin
  AssignFile(f, 'tmp.txt');
  Rewrite(f);
  AssignFile(errF, 'err.txt');
  Rewrite(errF);
  for j := -32 to 32 do
  begin
    errors[j] := 0;
    allErrors[j] := 0;
  end;

  for i := 80000000 to 180000000 do
  begin
    if i mod 1000000 = 0 then
    begin
      writeln(f);
      writeln(' errors:');
      for j := -32 to 32 do
      begin
        writeln('  ', j, ': ', format('%d', [errors[j]]));
        write(f, format('%.5f%%', [errors[j]/1800000]), #9);
        inc(allErrors[j], errors[j]);
        errors[j] := 0;
      end;
      writeln(i);
    end;
    intCos := CosWithSin(i);
    realCos := round(System.Cos(i*Pi/180/1E6)*1024*1024);
    error := round((realCos - intCos));
    if (error > -33) and (error < 32) then
      inc(errors[error])
    else
      inc(errors[32]);
    if abs(error) > 15 then
      writeln(errf, 'i = ', i, ' err = ', error);
  end;
  writeln(' All errors:');
  for j := -32 to 32 do
  begin
    writeln('  ', j, ': ', format('%d', [allErrors[j]]));
  end;
  CloseFile(f);
  CloseFIle(errF);
  writeln('completed');
end;

procedure ACosTest;
var
  i, j: integer;
  intValue: integer;
  realValue: real;
  f: TextFile;
  errF: TextFile;
  error: integer;
  errors: array[-32..32] of integer;
  allErrors: array[-32..32] of integer;
begin
  AssignFile(f, 'tmp.txt');
  Rewrite(f);
  AssignFile(errF, 'err.txt');
  Rewrite(errF);
  for j := -32 to 32 do
  begin
    errors[j] := 0;
    allErrors[j] := 0;
  end;

  for i := 0 to 1024*1024 do
  begin
    if i mod 5825 = 0 then
    begin
      writeln(' errors:');
      for j := -32 to 32 do
      begin
        writeln('  ', j, ': ', format('%d', [errors[j]]));
        write(f, format('%.5f%%', [errors[j]/58.25]), #9);
        inc(allErrors[j], errors[j]);
        errors[j] := 0;
      end;
      writeln(f);
      writeln(i);
    end;
    intValue := ACos(i);
    realValue := round(Math.ArcCos(i/1024/1024)*180/Pi*1E6);
    error := round((realValue - intValue));
    if (error > -33) and (error < 32) then
      inc(errors[error])
    else
      inc(errors[32]);
    if abs(error) > 8 then
      writeln(errf, 'i = ', i, ' err = ', error);
  end;
  writeln(' All errors:');
  for j := -32 to 32 do
  begin
    writeln('  ', j, ': ', format('%d', [allErrors[j]]));
  end;
  CloseFile(f);
  CloseFile(errF);
  writeln('completed');
end;

procedure DistanceTest;
var
  i, j: integer;
  intValue: integer;
  realValue: real;
  f: TextFile;
  errF: TextFile;
  error: integer;
  errors: array[-32..32] of integer;
  allErrors: array[-32..32] of integer;
begin
  AssignFile(f, 'tmp.txt');
  Rewrite(f);
  AssignFile(errF, 'err.txt');
  Rewrite(errF);
  for j := -32 to 32 do
  begin
    errors[j] := 0;
    allErrors[j] := 0;
  end;

  for i := 38000000 to 42000000 do
  begin
    if i mod 100000 = 0 then
    begin
      writeln(' errors:');
      write(f, i, #9);
      for j := -32 to 32 do
      begin
        writeln('  ', j, ': ', format('%d', [errors[j]]));
        write(f, format('%.5f%%', [errors[j]/58.25]), #9);
        inc(allErrors[j], errors[j]);
        errors[j] := 0;
      end;
      writeln(f);
      writeln(i);
    end;

    if i <> 40000000 then
    begin
      intValue := Distance(40000000, 40000000, 40000000, i);
      realValue := DistanceEtalon(40000000, 40000000, 40000000, i);
    end;

    error := round((realValue - intValue));
    if (error > -33) and (error < 32) then
      inc(errors[error])
    else
      inc(errors[32]);
    if abs(error) > 8 then
      writeln(errf, 'i = ', i, ' err = ', error);
  end;

  writeln(' All errors:');
  for j := -32 to 32 do
  begin
    writeln('  ', j, ': ', format('%d', [allErrors[j]]));
  end;
  CloseFile(f);
  CloseFile(errF);
  writeln('completed');
end;

var
  z: real;
begin
  try
//    arr := ReadFile('output.txt');
//    WriteTestFile('testOut.txt');
//    CalcAtanTable;
    DistanceTest;
    readln;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      readln;
    end;
  end;
end.
