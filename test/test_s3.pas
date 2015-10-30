{
    AWS
    Copyright (C) 2013-2015 Marcos Douglas - mdbs99

    See the files COPYING.GH, included in this
    distribution, for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}
unit test_s3;

{$i ../src/aws.inc}

interface

uses
  //rtl
  classes,
  sysutils,
  fpcunit,
  testregistry,
  //aws
  aws_base,
  aws_client,
  aws_s3;

type
  TAWSFakeClient = class(TInterfacedObject, IAWSClient)
  strict private
    FRequest: IAWSRequest;
    FResponse: IAWSResponse;
  public
    function Send(Request: IAWSRequest): IAWSResponse;
    function Request: IAWSRequest;
    function Response: IAWSResponse;
  end;

  TS3Test = class abstract(TTestCase)
  private
    FCredentials: IAWSCredentials;
    FClient: IAWSClient;
  protected
    procedure SetUp; override;
    function Client: TAWSFakeClient;
  end;

  TS3RegionTest = class(TS3Test)
  published
    procedure TestIsOnline;
    procedure TestImmutableBuckets;
  end;

  TS3BucketsTest = class(TS3Test)
  published
    procedure TestCheck;
    procedure TestGet;
    procedure TestDelete;
    procedure TestPut;
    procedure TestImmutable;
  end;

  TS3ObjectsTest = class(TS3Test)
  published
    procedure TestGet;
    procedure TestDelete;
    procedure TestPut;
    procedure TestOptions;
    procedure TestImmutable;
  end;

implementation

{ TAWSFakeClient }

function TAWSFakeClient.Send(Request: IAWSRequest): IAWSResponse;
var
  Code: Integer;
  Header, Text: string;
  Stream: TStringStream;
begin
  FRequest := Request;
  Code := -1;
  Header := '';
  Text := '';
  case Request.Method of
    'GET', 'HEAD', 'PUT', 'OPTIONS':
      begin
        Code := 200;
        Header := 'HTTP/1.1 200 OK';
        Text := 'OK';
      end;
    'DELETE':
      begin
        Code := 204;
        Header := 'HTTP/1.1 204 No Content';
        Text := 'No Content';
      end;
  end;
  Stream := TStringStream.Create(Header + #13 + Text);
  try
    FResponse := TAWSResponse.Create(
      Code, Header, Text, TAWSStream.Create(Stream)
    );
    Result := FResponse;
  finally
    Stream.Free;
  end;
end;

function TAWSFakeClient.Request: IAWSRequest;
begin
  Result := FRequest;
end;

function TAWSFakeClient.Response: IAWSResponse;
begin
  Result := FResponse;
end;

{ TS3Test }

procedure TS3Test.SetUp;
begin
  inherited SetUp;
  FCredentials := TAWSCredentials.Create('dummy_key', 'dummy_secret', False);
  FClient := TAWSFakeClient.Create;
end;

function TS3Test.Client: TAWSFakeClient;
begin
  Result := FClient as TAWSFakeClient;
end;

{ TS3RegionTest }

procedure TS3RegionTest.TestIsOnline;
var
  Rgn: IS3Region;
begin
  Rgn := TS3Region.Create(FClient);
  AssertTrue('Service denied', Rgn.Online);
  AssertEquals('GET', Client.Request.Method);
  AssertEquals('/', Client.Request.CanonicalizedResource);
end;

procedure TS3RegionTest.TestImmutableBuckets;
var
  Rgn: IS3Region;
begin
  Rgn := TS3Region.Create(FClient);
  AssertNotNull('Buckets not alive', Rgn.Buckets);
  AssertNotSame(Rgn.Buckets, Rgn.Buckets);
end;

{ TS3BucketsTest }

procedure TS3BucketsTest.TestCheck;
var
  Rgn: IS3Region;
begin
  Rgn := TS3Region.Create(FClient);
  AssertTrue(Rgn.Buckets.Check('myawsbucket'));
  AssertEquals('HEAD', Client.Request.Method);
  AssertEquals(200, Client.Response.Code);
  AssertEquals('HTTP/1.1 200 OK', Client.Response.Header);
  AssertEquals('OK', Client.Response.Text);
end;

procedure TS3BucketsTest.TestGet;
var
  Rgn: IS3Region;
  Bkt: IS3Bucket;
begin
  Rgn := TS3Region.Create(FClient);
  Bkt := Rgn.Buckets.Get('myawsbucket', '');
  AssertEquals('myawsbucket', Bkt.Name);
  AssertEquals('GET', Client.Request.Method);
  AssertEquals(200, Client.Response.Code);
  AssertEquals('HTTP/1.1 200 OK', Client.Response.Header);
  AssertEquals('OK', Client.Response.Text);
end;

procedure TS3BucketsTest.TestDelete;
var
  Rgn: IS3Region;
begin
  Rgn := TS3Region.Create(FClient);
  Rgn.Buckets.Delete('quotes', '/');
  AssertEquals('DELETE', Client.Request.Method);
  AssertEquals(204, Client.Response.Code);
  AssertEquals('HTTP/1.1 204 No Content', Client.Response.Header);
  AssertEquals('No Content', Client.Response.Text);
end;

procedure TS3BucketsTest.TestPut;
var
  Rgn: IS3Region;
begin
  Rgn := TS3Region.Create(FClient);
  Rgn.Buckets.Put('colorpictures', '/');
  AssertEquals('PUT', Client.Request.Method);
  AssertEquals(200, Client.Response.Code);
  AssertEquals('HTTP/1.1 200 OK', Client.Response.Header);
  AssertEquals('OK', Client.Response.Text);
end;

procedure TS3BucketsTest.TestImmutable;
var
  Rgn: IS3Region;
  Bkt: IS3Bucket;
begin
  Rgn := TS3Region.Create(FClient);
  Bkt := Rgn.Buckets.Get('myawsbucket', '');
  AssertNotSame(Bkt.Objects, Bkt.Objects);
end;

{ TS3ObjectsTest }

procedure TS3ObjectsTest.TestGet;
var
  Rgn: IS3Region;
  Bkt: IS3Bucket;
  Obj: IS3Object;
begin
  Rgn := TS3Region.Create(FClient);
  Bkt := Rgn.Buckets.Get('myawsbucket', '');
  Obj := Bkt.Objects.Get('foo.txt', '');
  AssertEquals(200, Client.Response.Code);
  AssertEquals('HTTP/1.1 200 OK', Client.Response.Header);
  AssertEquals('OK', Client.Response.Text);
  AssertTrue('Stream size is zero', Obj.Stream.Size > 0);
end;

procedure TS3ObjectsTest.TestDelete;
var
  Rgn: IS3Region;
  Bkt: IS3Bucket;
begin
  Rgn := TS3Region.Create(FClient);
  Bkt := Rgn.Buckets.Get('myawsbucket', '');
  Bkt.Objects.Delete('myobj');
  AssertEquals(204, Client.Response.Code);
  AssertEquals('HTTP/1.1 204 No Content', Client.Response.Header);
  AssertEquals('No Content', Client.Response.Text);
end;

procedure TS3ObjectsTest.TestPut;
var
  Rgn: IS3Region;
  Bkt: IS3Bucket;
begin
  Rgn := TS3Region.Create(FClient);
  Bkt := Rgn.Buckets.Get('myawsbucket', '');
  Bkt.Objects.Put('myobj', 'text/plain', nil, '');
  AssertEquals(200, Client.Response.Code);
  AssertEquals('HTTP/1.1 200 OK', Client.Response.Header);
  AssertEquals('OK', Client.Response.Text);
end;

procedure TS3ObjectsTest.TestOptions;
var
  Rgn: IS3Region;
  Bkt: IS3Bucket;
begin
  Rgn := TS3Region.Create(FClient);
  Bkt := Rgn.Buckets.Get('myawsbucket', '');
  Bkt.Objects.Options('myobj');
  AssertEquals(200, Client.Response.Code);
  AssertEquals('HTTP/1.1 200 OK', Client.Response.Header);
  AssertEquals('OK', Client.Response.Text);
end;

procedure TS3ObjectsTest.TestImmutable;
var
  Rgn: IS3Region;
  Bkt: IS3Bucket;
begin
  Rgn := TS3Region.Create(FClient);
  Bkt := Rgn.Buckets.Get('myawsbucket', '');
  AssertNotSame(Bkt.Objects, Bkt.Objects);
end;

initialization
  RegisterTest('s3.region', TS3RegionTest);
  RegisterTest('s3.buckets', TS3BucketsTest);
  RegisterTest('s3.objects', TS3ObjectsTest);

end.

