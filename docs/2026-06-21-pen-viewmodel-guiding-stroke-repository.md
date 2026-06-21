# PenViewModel에서 GuidingStrokeRepository로 이동한 책임

## 배경

펜 오버레이를 사진 저장 시점에 합성하려면 촬영 레이어가 현재 stroke 목록을 조회할 수 있어야 한다. 기존 구조에서는 `PenViewModel`이 stroke 상태와 네트워크 동기화를 함께 소유하고 있어서 `CameraViewModel`이 `PenViewModel`에 의존해야 하는 압력이 생겼다. 이번 변경은 stroke 상태의 단일 출처를 `GuidingStrokeRepository`로 옮기고, 각 ViewModel은 필요한 인터페이스만 바라보도록 정리한 것이다.

## 책임 비교

| 책임 | 기존 위치 | 변경 후 위치 |
| --- | --- | --- |
| 현재 세션 stroke 보관 | `PenViewModel.strokes` | `GuidingStrokeRepository.strokes` |
| 펜 툴 해제 후 유지되는 stroke 보관 | `PenViewModel.persistedStrokes` | `GuidingStrokeRepository.persistedStrokes` |
| 전체 삭제 후 undo 대상 보관 | `PenViewModel.deleteStrokes` | `GuidingStrokeRepository.deleteStrokes` |
| stroke 추가/수정/삭제/초기화 로직 | `PenViewModel` | `GuidingStrokeRepository` |
| `.penUpdated` 네트워크 이벤트 수신 | `PenViewModel.bind()` | `GuidingStrokeRepository.bind()` |
| `.penUpdated` 네트워크 이벤트 송신 | `PenViewModel.sendPenCommand(...)` | `GuidingStrokeRepository.sendPenCommand(...)` |
| UI 표시용 stroke 상태 제공 | `PenViewModel` 내부 배열 직접 관찰 | repository `AsyncStream<StrokeSnapshot>` 구독 후 `PenViewModel`에 반영 |
| 촬영 저장용 일반펜 stroke 조회 | 불가 또는 `PenViewModel` 의존 필요 | `GuidingStrokeRepository.captureDrawableStrokes()` |
| 토스트, 현재 역할, 최초 드로잉 여부 | `PenViewModel` | `PenViewModel` 유지 |

## 로직 이동 상세

<table>
  <thead>
    <tr>
      <th>로직</th>
      <th>기존 PenViewModel 중심 구조</th>
      <th>변경 후 Repository 중심 구조</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Stroke 추가</td>
      <td>
        <pre><code class="language-swift">func add(initialPoints: [CGPoint], isMagicPen: Bool) {
  let stroke = Stroke(
    points: initialPoints,
    isMagicPen: isMagicPen,
    author: currentRole
  )

  strokes.append(stroke)
  hasEverDrawn = true
  sendPenCommand(.add(stroke))
}</code></pre>
      </td>
      <td>
        <pre><code class="language-swift">func add(initialPoints: [CGPoint], isMagicPen: Bool) {
  hasEverDrawn = true

  repository.add(
    initialPoints: initialPoints,
    isMagicPen: isMagicPen,
    author: currentRole
  )
}</code></pre>
        <pre><code class="language-swift">func add(..., author: Role) -> UUID {
  let stroke = Stroke(...)
  strokes.append(stroke)
  sendPenCommand(.add(stroke))
  yieldSnapshot()
  return stroke.id
}</code></pre>
      </td>
    </tr>
    <tr>
      <td>Stroke 수정</td>
      <td>
        <pre><code class="language-swift">func updateStroke(id: UUID, points: [CGPoint], endDrawing: Bool) {
  guard let index = strokes.firstIndex(where: { $0.id == id }),
        strokes[index].author == currentRole else { return }

  strokes[index].points = points
  strokes[index].endDrawing = endDrawing
  sendPenCommand(.replace(strokes[index]))
}</code></pre>
      </td>
      <td>
        <pre><code class="language-swift">func updateStroke(id: UUID, points: [CGPoint], endDrawing: Bool) {
  repository.updateStroke(
    id: id,
    points: points,
    endDrawing: endDrawing,
    author: currentRole
  )
}</code></pre>
        <pre><code class="language-swift">func updateStroke(..., author: Role) {
  guard let index = strokes.firstIndex(where: { $0.id == id }),
        strokes[index].author == author else { return }

  strokes[index].points = points
  strokes[index].endDrawing = endDrawing
  sendPenCommand(.replace(strokes[index]))
  yieldSnapshot()
}</code></pre>
      </td>
    </tr>
    <tr>
      <td>Stroke 저장</td>
      <td>
        <pre><code class="language-swift">func saveStroke() {
  let myStrokes = strokes.filter { $0.author == currentRole }

  persistedStrokes.append(contentsOf: myStrokes)
  strokes.removeAll { $0.author == currentRole }
  deleteStrokes.removeAll { $0.author == currentRole }
}</code></pre>
      </td>
      <td>
        <pre><code class="language-swift">func saveStroke() {
  repository.saveStroke(for: currentRole)
}</code></pre>
        <pre><code class="language-swift">func saveStroke(for author: Role) {
  let myStrokes = strokes.filter { $0.author == author }

  persistedStrokes.append(contentsOf: myStrokes)
  strokes.removeAll { $0.author == author }
  deleteStrokes.removeAll { $0.author == author }
  yieldSnapshot()
}</code></pre>
      </td>
    </tr>
    <tr>
      <td>전체 삭제와 undo</td>
      <td>
        <pre><code class="language-swift">func deleteAll() {
  deleteStrokes = persistedStrokes + strokes
  strokes.removeAll()
  persistedStrokes.removeAll()
  sendPenCommand(.deleteAll)
}

func undo() {
  persistedStrokes = deleteStrokes
  deleteStrokes.removeAll()
  sendPenCommand(.undo)
}</code></pre>
      </td>
      <td>
        <pre><code class="language-swift">func deleteAll() {
  repository.deleteAll()
}

func undo() {
  repository.undo()
}</code></pre>
        <pre><code class="language-swift">func deleteAll() {
  deleteStrokes = persistedStrokes + strokes
  strokes.removeAll()
  persistedStrokes.removeAll()
  sendPenCommand(.deleteAll)
  yieldSnapshot()
}

func undo() {
  persistedStrokes = deleteStrokes
  deleteStrokes.removeAll()
  sendPenCommand(.undo)
  yieldSnapshot()
}</code></pre>
      </td>
    </tr>
    <tr>
      <td>네트워크 수신</td>
      <td>
        <pre><code class="language-swift">func bind() {
  networkService.networkEventPublisher
    .compactMap { event -> PenEventType? in
      guard case .penUpdated(let payload) = event else { return nil }
      return payload
    }
    .sink { [weak self] event in
      self?.applyPenEvent(event)
    }
}</code></pre>
      </td>
      <td>
        <pre><code class="language-swift">private func bind() {
  networkService.networkEventPublisher
    .compactMap { event -> PenEventType? in
      guard case .penUpdated(let payload) = event else { return nil }
      return payload
    }
    .sink { [weak self] event in
      self?.applyPenEvent(event)
      self?.yieldSnapshot()
    }
}</code></pre>
        <pre><code class="language-swift">private func observeSnapshots() {
  Task {
    for await snapshot in repository.snapshots {
      strokes = snapshot.strokes
      persistedStrokes = snapshot.persistedStrokes
      deleteStrokes = snapshot.deleteStrokes
    }
  }
}</code></pre>
      </td>
    </tr>
  </tbody>
</table>

표의 코드는 리뷰 이해를 위한 축약 예시다. 핵심은 `PenViewModel`이 stroke 배열과 네트워크 이벤트를 직접 조작하던 흐름을 끊고, 사용자 액션을 repository write API로 전달하는 역할만 맡도록 변경한 것이다.

## 촬영 저장 관점의 변화

`CameraViewModel`은 더 이상 펜 화면의 ViewModel을 몰라도 된다. 촬영 시점에는 `GuidingStrokeRepository.captureDrawableStrokes()`를 호출해 저장 가능한 stroke snapshot을 가져온다.

저장 가능한 stroke의 기준은 다음과 같다.

- `persistedStrokes + strokes`에 포함되어 있음
- point가 2개 이상임
- `isMagicPen == false`

이 결과는 `DrawableStroke`로 변환되어 `CameraManager`에 전달된다. `CameraManager`는 사진 저장 직전 `PhotoOverlayCompositingService`로 원본 `PhotoOuput`을 합성 가능한 output으로 가공한다. `DrawableStroke`는 사진 합성에 필요한 id, normalized points, author만 담기 때문에 카메라 저장 로직이 펜 UI 상태에 의존하지 않는다.

## 남긴 책임

`PenViewModel`에는 다음 책임을 의도적으로 남겼다.

- 현재 역할(`currentRole`)과 기본 역할 결정
- 최초 드로잉 여부(`hasEverDrawn`)
- 펜/매직펜 관련 toast 노출 상태
- View가 사용하는 `strokes`, `persistedStrokes`, `deleteStrokes` 관찰 상태

즉, `PenViewModel`은 “펜 UI 상태와 사용자 액션 전달자”이고, `GuidingStrokeRepository`는 “stroke 상태와 동기화의 단일 출처”다.

## 예상되는 문제

현재 카메라 설정에서는 `AVCapturePhotoOutput.isAutoDeferredPhotoDeliveryEnabled`를 켜고 있다. 이 설정이 켜져 있으면 시스템이 촬영 결과를 일반 photo data로 바로 전달하지 않고 `AVCaptureDeferredPhotoProxy`로 먼저 전달할 수 있다.

일반 저장 경로는 최종 still image data를 `.photo` 리소스로 저장한다.

```swift
PhotoLibraryHelpers.saveToPhotoLibrary(photoOutput.imageData)
```

deferred 저장 경로는 `AVCaptureDeferredPhotoProxy.fileDataRepresentation()`에서 얻은 data를 `.photoProxy` 리소스로 저장한다.

```swift
PhotoLibraryHelpers.saveProxyToPhotoLibrary(photoOutput.imageData)
```

펜 오버레이 저장이 켜진 상태에서 deferred 경로를 그대로 허용하면 `CameraManager`가 저장 직전 `PhotoOverlayCompositingService`로 `PhotoOuput`을 가공한다. 이 경우 원본 proxy data가 그대로 저장되지 않고, proxy data를 `UIImage`로 읽어 오버레이를 합성한 뒤 새 JPEG로 인코딩한 결과가 `.photoProxy`로 저장된다.

```swift
let photoOutput = process(.livePhoto(
  thumbnail: thumbnail,
  imageData: deferredPhotoProxyData,
  videoData: movieData
))

PhotoLibraryHelpers.saveDeferredLivePhotoToPhotosLibrary(
  proxyData: photoOutput.imageData,
  livePhotoMovieURL: outputFileURL
)
```

이 경로의 리스크는 다음과 같다.

- 새로 인코딩한 JPEG가 Photos에서 deferred photo proxy 리소스로 완성되는지 public API 수준에서 명확하게 검증되어 있지 않다.
- deferred Live Photo에서 `.photoProxy + .pairedVideo` 조합이 정상 저장되더라도, 이후 시스템이 최종 고품질 사진으로 완성하는 과정에서 오버레이가 유지되는지 확인이 필요하다.
- 현재 delegate는 일반 photo callback과 deferred proxy callback의 이중 저장을 명시적으로 guard하지 않는다. 지금까지 큰 사이드이펙트는 확인되지 않았고, 문제가 생겨도 예상되는 영향은 중복 저장이다.

Bob의 셀프 QA에서 상대방 폰에는 합성된 Live Photo가 전송되지만, 촬영 폰에는 합성된 Live Photo가 잠깐 보였다가 잠시 뒤 합성되지 않은 버전으로 바뀌는 현상이 확인됐다. 이는 촬영 폰의 Photos가 `.photoProxy`를 먼저 보여준 뒤 시스템이 최종 deferred still image로 완성하면서, 오버레이가 없는 원본 결과로 대체되는 흐름으로 판단했다.

이번 PR에서는 오버레이 저장 대상 stroke가 있을 때 deferred photo delivery를 끈다.

```swift
performCapturePhoto(allowsDeferredPhotoDelivery: false) { photoOutput in
  photoOverlayCompositingService.composite(photoOutput: photoOutput, strokes: drawableStrokes)
}
```

오버레이 stroke가 없는 촬영은 기존처럼 deferred photo delivery를 허용한다.

```swift
performCapturePhoto(allowsDeferredPhotoDelivery: true)
```

따라서 일반 촬영은 기존 deferred 최적화를 유지하고, 펜 오버레이가 실제로 합성되는 촬영만 최종 photo data 경로를 사용한다.
