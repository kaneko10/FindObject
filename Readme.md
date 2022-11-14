# 3次元再構成ステップ

①　現実空間のマッピング作業

3次元モデルとして構築を行いたい現実空間をデバイスのカメラで撮影しながら移動する．この時．現実空間の形状を再現したメッシュモデルをARKitを用いることで取得することができる．本システムの3次元再構成では，このメッシュモデルにテクスチャを割り当てることで実現する．

②　パラメータの取得

テクスチャとして使用するRGB画像や割り当てのために必要となる深度情報，デバイスの位置等のパラメータの取得は，下記のMppingSupportフレームワークを利用する．

③　テクスチャの割り当て

マッピングで取得したパラメータを用いてメッシュの各ポリゴンのテクスチャ座標の計算を行う．これには，下記のGPUTextureCalculateを利用する．

④　3次元モデルの構築

計算したテクスチャ座標を基に3次元モデルの構築を行う．これはARKitのカスタムジオメトリで実現する．


# 3次元再構成に関するフレームワーク

## MappingSupport

*　主な機能

  ・　テクスチャとして使用するRGB画像や割り当てのために必要となる深度情報，デバイスの位置等のパラメータの取得
  
  ・　マッピング可視化によるユーザのマッピング支援

* インスタンスの作成

```swift
let view: ARSCNView
let mp = MappingSupport.depth_Renderer(session: view.session, metalDevice: view.device!, sceneView: view)
mp.drawRectResized(size: view.bounds.size)
```

* パラメータ取得，マッピング支援の前準備

毎フレーム呼び出す必要があるため，renderer(_:didRenderScene:atTime:)で呼び出す．

```swift
mp.draw_depth() //パラメータ取得の実行
mp.draw_mapping() //マッピング支援の実行
```

* 各データの取得

それぞれData型とbool値を返す．boolがTrueならデータの取得成功，Falseなら取得失敗である．

```swift
let (depthData, depthBool) = mp.get_depthData()
let (imgData, imgBool) = mp.get_imgData()
let (jsonData, jsonBool) = mp.get_jsonData()
```

## GPUTextureCalculate
