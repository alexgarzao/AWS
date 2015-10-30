{
    AWS
    Copyright (C) 2013-2015 Marcos Douglas - mdbs99

    See the file LICENSE.txt, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}
unit aws_http;

{$i aws.inc}

interface

uses
  //rtl
  sysutils,
  classes,
  //synapse
  httpsend,
  synautil,
  ssl_openssl,
  //aws
  aws_base;

type
  IHTTPRequest = interface(IInterface)
  ['{12744C05-22B6-45BF-B47A-49813F6B64B6}']
    function Method: string;
    function SubDomain: string;
    function Domain: string;
    function Resource: string;
    function SubResource: string;
    function ContentType: string;
    function ContentMD5: string;
    function CanonicalizedAmzHeaders: string;
    function CanonicalizedResource: string;
    function Stream: IAWSStream;
    function ToString: string;
  end;

  IHTTPResponse = interface(IInterface)
  ['{6E7E8524-88B5-48B1-95FF-30D0DF40D8F7}']
    function Code: Integer;
    function Header: string;
    function Text: string;
    function Stream: IAWSStream;
  end;

  IHTTPSender = interface(IInterface)
  ['{DF9B2674-D60C-4F40-AD6A-AE158091212D}']
    function Send: IHTTPResponse;
  end;

  THTTPRequest = class sealed(TInterfacedObject, IHTTPRequest)
  private
    FMethod: string;
    FSubDomain: string;
    FDomain: string;
    FResource: string;
    FSubResource: string;
    FContentType: string;
    FContentMD5: string;
    FCanonicalizedAmzHeaders: string;
    FCanonicalizedResource: string;
    FStream: IAWSStream;
  public
    constructor Create(const Method, SubDomain, Domain, Resource, SubResource, ContentType, ContentMD5,
      CanonicalizedAmzHeaders, CanonicalizedResource: string; Stream: IAWSStream);
    constructor Create(const Method, SubDomain, Domain, Resource, SubResource, ContentType, ContentMD5,
      CanonicalizedAmzHeaders, CanonicalizedResource: string);
    constructor Create(const Method, SubDomain, Domain, Resource, SubResource, CanonicalizedResource: string);
    constructor Create(const Method, SubDomain, Domain, Resource, CanonicalizedResource: string);
    constructor Create(const Method, SubDomain, Domain, Resource, CanonicalizedResource: string; Stream: IAWSStream);
    constructor Create(const Method, SubDomain, Domain, CanonicalizedResource: string);
    function Method: string;
    function SubDomain: string;
    function Domain: string;
    function Resource: string;
    function SubResource: string;
    function ContentType: string;
    function ContentMD5: string;
    function CanonicalizedAmzHeaders: string;
    function CanonicalizedResource: string;
    function Stream: IAWSStream;
    function ToString: string; override;
  end;

  THTTPResponse = class sealed(TInterfacedObject, IHTTPResponse)
  private
    FCode: Integer;
    FHeader: string;
    FText: string;
    FStream: IAWSStream;
  public
    constructor Create(Code: Integer; const Header, Text: string; Stream: IAWSStream);
    constructor Create(Code: Integer; const Header, Text: string);
    constructor Create(Origin: IHTTPResponse);
    destructor Destroy; override;
    function Code: Integer;
    function Header: string;
    function Text: string;
    function Stream: IAWSStream;
  end;

  THTTPSender = class sealed(TInterfacedObject, IHTTPSender)
  private
    FSender: THTTPSend;
    FMethod: string;
    FHeader: string;
    FContentType: string;
    FURL: string;
    FStream: IAWSStream;
  public
    constructor Create(const Method, Header, ContentType, URL: string; Stream: IAWSStream);
    destructor Destroy; override;
    function Send: IHTTPResponse;
  end;

implementation

{ THTTPRequest }

constructor THTTPRequest.Create(const Method, SubDomain, Domain, Resource, SubResource,
  ContentType, ContentMD5, CanonicalizedAmzHeaders,
  CanonicalizedResource: string; Stream: IAWSStream);
begin
  FMethod := Method;
  FSubDomain := SubDomain;
  FDomain := Domain;
  FResource := Resource;
  FSubResource := SubResource;
  FContentType := ContentType;
  FContentMD5 := ContentMD5;
  FCanonicalizedAmzHeaders := CanonicalizedAmzHeaders;
  FCanonicalizedResource := CanonicalizedResource;
  FStream := Stream
end;

constructor THTTPRequest.Create(const Method, SubDomain, Domain, Resource, SubResource,
  ContentType, ContentMD5, CanonicalizedAmzHeaders,
  CanonicalizedResource: string);
begin
  Create(
    Method, SubDomain, Domain, Resource, SubResource, ContentType,
    ContentMD5, CanonicalizedAmzHeaders, CanonicalizedResource,
    TAWSStream.Create
  );
end;

constructor THTTPRequest.Create(const Method, SubDomain, Domain, Resource, SubResource,
  CanonicalizedResource: string);
begin
  Create(
    Method, SubDomain, Domain, Resource, SubResource, '',
    '', '', CanonicalizedResource,
    TAWSStream.Create
  );
end;

constructor THTTPRequest.Create(const Method, SubDomain, Domain, Resource,
  CanonicalizedResource: string);
begin
  Create(
    Method, SubDomain, Domain, Resource, '', '',
    '', '', CanonicalizedResource,
    TAWSStream.Create
  );
end;

constructor THTTPRequest.Create(const Method, SubDomain, Domain, Resource,
  CanonicalizedResource: string; Stream: IAWSStream);
begin
  Create(
    Method, SubDomain, Domain, Resource, '', '',
    '', '', CanonicalizedResource,
    Stream
  );
end;

constructor THTTPRequest.Create(const Method, SubDomain, Domain, CanonicalizedResource: string);
begin
  Create(
    Method, SubDomain, Domain, '', '', '',
    '', '', CanonicalizedResource,
    TAWSStream.Create
  );
end;

function THTTPRequest.Method: string;
begin
  Result := FMethod;
end;

function THTTPRequest.SubDomain: string;
begin
  Result := FSubDomain;
end;

function THTTPRequest.Domain: string;
begin
  Result := FDomain;
end;

function THTTPRequest.Resource: string;
begin
  Result := FResource;
end;

function THTTPRequest.SubResource: string;
begin
  Result := FSubResource;
end;

function THTTPRequest.ContentType: string;
begin
  Result := FContentType;
end;

function THTTPRequest.ContentMD5: string;
begin
  Result := FContentMD5;
end;

function THTTPRequest.CanonicalizedAmzHeaders: string;
begin
  Result := FCanonicalizedAmzHeaders;
end;

function THTTPRequest.CanonicalizedResource: string;
begin
  Result := FCanonicalizedResource;
end;

function THTTPRequest.Stream: IAWSStream;
begin
  Result := FStream;
end;

function THTTPRequest.ToString: string;
begin
  with TStringList.Create do
  try
    Add('Method=' + FMethod);
    Add('Resource=' + FResource);
    Add('SubResource=' + FSubResource);
    Add('ContentType=' + FContentType);
    Add('ContentMD5=' + FContentMD5);
    Add('CanonicalizedAmzHeaders=' + FCanonicalizedAmzHeaders);
    Add('CanonicalizedResource=' + FCanonicalizedResource);
    Result := Text;
  finally
    Free;
  end;
end;

{ THTTPResponse }

constructor THTTPResponse.Create(Code: Integer; const Header, Text: string;
  Stream: IAWSStream);
begin
  FCode := Code;
  FHeader := Header;
  FText := Text;
  FStream := Stream;
end;

constructor THTTPResponse.Create(Code: Integer; const Header, Text: string);
begin
  Create(Code, Header, Text, nil);
end;

constructor THTTPResponse.Create(Origin: IHTTPResponse);
begin
  Create(Origin.Code, Origin.Header, Origin.Text, Origin.Stream);
end;

destructor THTTPResponse.Destroy;
begin
  inherited Destroy;
end;

function THTTPResponse.Code: Integer;
begin
  Result := FCode;
end;

function THTTPResponse.Header: string;
begin
  Result := FHeader;
end;

function THTTPResponse.Text: string;
begin
  Result := FText;
end;

function THTTPResponse.Stream: IAWSStream;
begin
  Result := FStream;
end;

{ THTTPSender }

constructor THTTPSender.Create(const Method, Header, ContentType, URL: string;
  Stream: IAWSStream);
begin
  inherited Create;
  FSender := THTTPSend.Create;
  FSender.Protocol := '1.0';
  FMethod := Method;
  FHeader := Header;
  FContentType := ContentType;
  FURL := URL;
  FStream := Stream;
end;

destructor THTTPSender.Destroy;
begin
  FSender.Free;
  inherited Destroy;
end;

function THTTPSender.Send: IHTTPResponse;
begin
  FSender.Clear;
  FSender.Headers.Add(FHeader);
  FSender.MimeType := FContentType;
  FStream.SaveToStream(FSender.Document);
  FSender.HTTPMethod(FMethod, FURL);
  Result := THTTPResponse.Create(
    FSender.ResultCode,
    FSender.Headers.Text,
    FSender.ResultString,
    TAWSStream.Create(FSender.Document)
  );
end;

end.
