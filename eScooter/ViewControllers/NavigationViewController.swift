//
//  NavigationViewController.swift
//  eScooter
//
//  Created by Dove on 06/12/2020.
//  Copyright © 2020 Dove. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Speech

class NavigationViewcontroller: BaseViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    @IBOutlet weak var img_battery: UIImageView!
    @IBOutlet weak var lbl_speed: UILabel!
    @IBOutlet weak var img_mode: UIImageView!
    @IBOutlet weak var lbl_trip: UILabel!
    @IBOutlet weak var lbl_odo: UILabel!
    @IBOutlet weak var img_pointer: UIImageView!
    @IBOutlet weak var lbl_battery: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    var locationManager: CLLocationManager!
    @IBOutlet weak var textfieldAddress: UITextField!
    @IBOutlet weak var tableviewSearch: UITableView!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var img_speech: UIImageView!
    @IBOutlet weak var view_recording: UIView!
    @IBOutlet weak var btn_arrow_back: UIButton!
    var autocompleteResults :[GApiResponse.Autocomplete] = []

    public var cur_location:CLLocationCoordinate2D!
    public var destinationCoordinate:CLLocationCoordinate2D?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))  //1
    public var speechavailable = false
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.btn_arrow_back.imageView?.contentMode = .scaleAspectFit
        self.img_speech.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.recognizeSpeech)))
        self.textfieldAddress.delegate = self
        self.tableviewSearch.delegate = self
        self.tableviewSearch.dataSource = self
        self.view_recording.isHidden = true
        initMap()
        initSpeech()
    }
    @IBAction func onStop(_ sender: Any) {
        self.recognizeSpeech()
    }
    
    @IBAction func btn_back_down(_ sender: Any) {
        self.btn_arrow_back.setAssetImage(name: "ic_arrow_up_touch")
    }
    @IBAction func btn_back_up(_ sender: Any) {
        self.btn_arrow_back.setAssetImage(name: "ic_arrow_up_nor")
        self.goBack()
    }
    @objc func recognizeSpeech(){
        if(self.speechavailable == false){
            self.showToast(title: "Error", body: "Not available speech")
        }
        if self.audioEngine.isRunning {
            self.view_recording.isHidden = true
            self.audioEngine.stop()
            self.recognitionRequest?.endAudio()
        } else {
            self.view_recording.isHidden = false
            self.startRecording()
        }
    }
    func showRecording(){
    }
    func showResults(string:String){
        var input = GInput()
        input.keyword = string
        GoogleApi.shared.callApi(input: input) { (response) in
            if response.isValidFor(.autocomplete) {
                DispatchQueue.main.async {
                    self.searchView.isHidden = false
                    self.autocompleteResults = response.data as! [GApiResponse.Autocomplete]
                    self.tableviewSearch.reloadData()
                }
            } else { print(response.error ?? "ERROR") }
        }
    }
    func hideResults(){
        searchView.isHidden = true
        autocompleteResults.removeAll()
        tableviewSearch.reloadData()
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 3
        return renderer
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last{
            self.cur_location = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            if let destination = self.destinationCoordinate {
                
                let viewRegion = MKCoordinateRegion(center: self.cur_location, latitudinalMeters: 200, longitudinalMeters: 200)
                self.mapView.setRegion(viewRegion, animated: false)
                
                self.showRouteOnMap(pickupCoordinate: self.cur_location, destinationCoordinate: destination)
            }
        }
    }
    func initMap(){
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = MKMapType(rawValue: 0)!
        mapView.userTrackingMode = MKUserTrackingMode(rawValue: 2)!
//        mapView.showsCompass = true
        mapView.showsCompass = false // hides current compass, which shows only on map turning
        let screenSize: CGRect = UIScreen.main.bounds
        let compassBtn = MKCompassButton(mapView: mapView)
        compassBtn.frame.origin = CGPoint(x: screenSize.width-40, y: 8)
        compassBtn.compassVisibility = .visible
        mapView.addSubview(compassBtn)

        
    }
    @objc func back() {
       self.view.layer.add(CATransition().segueFromTop(), forKey: nil)
       self.dismiss(animated: false, completion: nil)
    }
    func setSpeed(speed: Float){
        self.lbl_speed.text = String(format:"%.1f", speed)
        let max:Float = 286
        let angle = (max / 30 * speed) * .pi / 180;
        self.img_pointer.transform = CGAffineTransform(rotationAngle: CGFloat(angle))

    }
    func setBattery(battery: Int){
        var battery = battery
        if(battery < 0){
            battery = 0
        }
        if(battery > 100){
            battery = 100
        }
        
        self.lbl_battery.text = String(battery)+"%"
        var battery_image:String!
        if (battery == 0) {
            battery_image = "ic_battery_0"
        }
        else if (battery <= 20) {
            battery_image = "ic_battery_20"
        }
        else if (battery <= 40) {
            battery_image = "ic_battery_40"
        }
        else if (battery <= 60) {
            battery_image = "ic_battery_60"
        }
        else if (battery <= 80) {
            battery_image = "ic_battery_80"
        }
        else if (battery <= 100) {
            battery_image = "ic_battery_100"
        }

        self.img_battery.image = UIImage(named: battery_image)
    }
    func setMode(mode:Int){
        var mode_image:String!
        if(mode == 1){
            mode_image = "ic_mode1_nor"
        }else if(mode == 2){
            mode_image = "ic_mode2_nor"
        }else if(mode == 3){
            mode_image = "ic_mode3_nor"
        }
        self.img_mode.image = UIImage(named: mode_image)
    }
    func didUpdateValues(){
        self.lbl_trip.text = String(format:"%.2f", Utils.mScooterInfo.trip)
        self.lbl_odo.text = String(format:"%.2f", Utils.mScooterInfo.odo)
        self.setSpeed(speed: Utils.mScooterInfo.speed)
        self.setBattery(battery: Utils.mScooterInfo.battery)
        self.setMode(mode:Utils.mScooterInfo.speedMode)
    }
}

extension NavigationViewcontroller : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        hideResults() ; return true
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text! as NSString
        let fullText = text.replacingCharacters(in: range, with: string)
        if fullText.count > 2 {
            showResults(string:fullText)
        }else{
            hideResults()
        }
        return true
    }
}
extension NavigationViewcontroller: SFSpeechRecognizerDelegate{
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        self.speechavailable = available
    }
    func initSpeech(){
        speechRecognizer!.delegate = self
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            self.speechavailable = true
            switch authStatus {
                case .authorized:
                    self.speechavailable = true
                case .denied:
                    self.showToast(title: "Warning", body: "User denied access to speech recognition")
                case .restricted:
                    self.showToast(title: "Warning", body: "Speech recognition restricted on this device")
                case .notDetermined:
                    self.showToast(title: "Warning", body: "Speech recognition not yet authorized")
            @unknown default: break
            }
        }
    }
    func startRecording(){
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.showToast(title:"Warning", body:"audioSession properties weren't set because of an error.")
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        if (inputNode == nil){
            self.showToast(title:"Warning", body:"Audio engine has no input node")
            return
        }
        guard let recognitionRequest = recognitionRequest else {
            self.showToast(title:"Warning", body:"Unable to create an SFSpeechAudioBufferRecognitionRequest object")
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer!.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            if result != nil {
                self.textfieldAddress.text = result?.bestTranscription.formattedString
                self.showToast(body: result?.bestTranscription.formattedString)
                isFinal = (result?.isFinal)!
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.speechavailable = false
            }
        })
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            self.showToast(body: "audioEngine couldn't start because of an error.")
        }
        self.textfieldAddress.text = "Say something, I'm listening!"
    }
}
extension NavigationViewcontroller : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autocompleteResults.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchResultCell")
        let label = cell?.viewWithTag(1) as! UILabel
        label.text = autocompleteResults[indexPath.row].formattedAddress
        return cell!
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        textfieldAddress.text = autocompleteResults[indexPath.row].formattedAddress
        textfieldAddress.resignFirstResponder()
        var input = GInput()
        input.keyword = autocompleteResults[indexPath.row].placeId
        GoogleApi.shared.callApi(.placeInformation,input: input) { (response) in
            if let place =  response.data as? GApiResponse.PlaceInfo, response.isValidFor(.placeInformation) {
                DispatchQueue.main.async {
                    self.searchView.isHidden = true
                    if let lat = place.latitude, let lng = place.longitude {
                        let center  = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                        self.mapView.setRegion(region, animated: true)
                        
                        self.destinationCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                        self.showRouteOnMap(pickupCoordinate: self.cur_location, destinationCoordinate: self.destinationCoordinate!)

                        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
                            self.initMap()
                        }
                    }
                    self.tableviewSearch.reloadData()
                }
            } else { print(response.error ?? "ERROR") }
        }
    }
    
    func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        let sourcePlacemark = MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
      
        let destinationAnnotation = MKPointAnnotation()
        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }

        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotation(destinationAnnotation)
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile

        let directions = MKDirections(request: directionRequest)
        directions.calculate {
            (response, error) -> Void in
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                return
            }
            let route = response.routes[0]
            self.mapView.removeOverlays(self.mapView.overlays)
            self.mapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
        }
    }
}
