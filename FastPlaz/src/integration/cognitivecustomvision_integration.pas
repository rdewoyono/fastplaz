unit cognitivecustomvision_integration;

{
  Cognitive Computer Vision Domain Specific

  [x] USAGE
  with TCognitiveCustomVision.Create do
  begin
    Token := 'yourcognitivetoken;
    Model := 'celebrities';
    Result := Scan('imageURL');
    Free;
  end;

  [x] Example result from customvision
  {
      "Id": "aad13c94-d27b-42f1-a8ad-2232019e45ac",
      "Project": "0526c52f-bfb7-49fc-8e54-dff443c30a3a",
      "Iteration": "d66e5678-66d5-42d7-ad9f-d92297798721",
      "Created": "2017-11-30T19:09:59.0577809Z",
      "Predictions": [
          {
              "TagId": "25977720-c7c2-46a0-ba17-5de8dca11273",
              " ": "jantung",
              "Probability": 4.619192e-7
          },
          {
              "TagId": "f6d6b297-3734-4abe-a323-8ec8f1f6e36a",
              "Tag": "paru paru",
              "Probability": 1.796196e-10
          }
      ]
  }

}

{$mode objfpc}{$H+}

interface

uses
  fpjson,
  common, http_lib, logutil_lib,
  Classes, SysUtils;

type

  { TCognitiveCustomVision }

  TCognitiveCustomVision = class(TInterfacedObject)
  private
    FImageURL: string;
    FKey: string;
    FResultText: string;
    FURL: string;
    jsonData: TJSONData;
    function generateURL: string;
    function getData(APath: string): string;
  public
    constructor Create;
    destructor Destroy; override;

    property ImageURL: string read FImageURL write FImageURL;

    function Prediction: string;
    function Prediction(AImageURL: string): string;
    function PredictionAsJSON(AImageURL: string): string;
  published
    property URL: string read FURL write FURL;
    property Key: string read FKey write FKey;
    property Data: TJSONData read jsonData;

    property ResultText: string read FResultText;
  end;

implementation

const
  _COGNITIVE_CUSTOMVISION_DEFAULT_URL =
    'https://southcentralus.api.cognitive.microsoft.com/customvision/v1.0/Prediction/';

var
  Response: IHTTPResponse;

{ TCognitiveCustomVision }

function TCognitiveCustomVision.generateURL: string;
begin
  Result := FURL;
end;

function TCognitiveCustomVision.getData(APath: string): string;
begin
  Result := '';
  try
    Result := jsonGetData(jsonData, APath);
  except
  end;
end;

constructor TCognitiveCustomVision.Create;
begin
  FURL := '';
  FKey := '';
end;

destructor TCognitiveCustomVision.Destroy;
begin
  if Assigned(jsonData) then
    jsonData.Free;
end;

function TCognitiveCustomVision.Prediction: string;
begin
  Result := Prediction(FImageURL);
end;

function TCognitiveCustomVision.Prediction(AImageURL: string): string;
var
  i: Integer;
  s: String;
begin
  Result := PredictionAsJSON(AImageURL);
  if Result = '' then
    Exit;

  jsonData := GetJSON(Result);
  Result := '';
  repeat
    s := getData('Predictions[' + i2s(i) + '].Tag');
    if s <> '' then
    begin
      Result := Result + '\n' + s + ':';
      Result := Result + getData('Predictions[' + i2s(i) + '].Probability');
    end;
    i := i + 1;
  until s = '';
end;

function TCognitiveCustomVision.PredictionAsJSON(AImageURL: string): string;
var
  _body: string;
begin
  Result := '';
  FResultText := '';
  if FKey = '' then
    Exit;
  if AImageURL = '' then
    Exit;

  with THTTPLib.Create(generateURL) do
  begin
    try
      ContentType := 'application/json';
      AddHeader('Prediction-Key', FKey);
      _body := '{"url":"' + AImageURL + '"}';
      RequestBody := TStringStream.Create(_body);
      Response := Post;
      FResultText := Response.ResultText;
      LogUtil.Add(FResultText, 'CUSTOMVISION');
      if Response.ResultCode = 200 then
      begin
        Result := Response.ResultText;
      end;
    except
      on E: Exception do
        LogUtil.Add(E.Message, 'CUSTOMVISION');
    end;
    Free;
  end;

end;

end.
