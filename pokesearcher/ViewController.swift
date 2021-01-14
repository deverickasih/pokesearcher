//
//  ViewController.swift
//  pokesearcher
//
//  Created by JAN FREDRICK on 13/01/21.
//  Copyright © 2021 JFSK. All rights reserved.
//

import UIKit
import PokemonAPI
import JGProgressHUD
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    struct pokeObject : Codable {
        var id : Int?
        var name : String
        var url : String
        var image : String?
        var pokemon : PKMPokemon?
        var fetched : Bool? = false
        
        private enum CodingKeys: String, CodingKey {
            case name
            case url
        }
    }
    
    var pokesList : [pokeObject] = []
    var pokeListToAdd : [pokeObject] = []
    
    var tableView : UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if UIScreen.main.bounds.height >= 812 {
            tableView = UITableView(frame: CGRect(x: 0, y: 44, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 78))
        }else{
            tableView = UITableView(frame: CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 20))
        }
        
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.clipsToBounds = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        self.fetchData()
        
    }
    
    let hud = JGProgressHUD(style: .dark)
    
    func fetchData() {
        
        if fetchNext50 == "" {
            return
        }
        
        hud.textLabel.text = "fetching"
        hud.show(in: self.view)
        
        AF.request(fetchNext50).response(completionHandler: { (result) in
            
            self.hud.dismiss()
            
            if result.error != nil {
                
                self.showMessage(title: "Error", msg: result.error!.localizedDescription, btn: "OK", note: "") // note can be used to try fetching data once again
                
                return
            }
            
            let jsonData = JSON(result.data!)
            
            fetchNext50 = jsonData["next"].stringValue
            let pokeResult = jsonData["results"].arrayValue
            
            print("next : \(fetchNext50)")
            print(jsonData["results"])
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                self.pokeListToAdd = try decoder.decode([pokeObject].self, from: """
                    \(pokeResult)
                    """.data(using: .utf8)!)
                self.pokesList.append(contentsOf: self.pokeListToAdd)
                self.tableView.reloadData()
            } catch {
                print("50 Object Parse Error = \(error.localizedDescription)")
            }
            
        })
    }
    
    func showMessage(title: String, msg: String, btn: String, note: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: btn, style: .cancel, handler: { (alert) in
            if note == "" {
                // do nothing
            }else{
                // do something
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func fetchPoke(id: String, for cell: tbCell) {
        
        PokemonAPI.init().pokemonService.fetchPokemon(id) { result in
            
            switch result {
            case .success(let pokemon) :
                self.pokesList[cell.cellIndex].id = pokemon.id
                self.pokesList[cell.cellIndex].pokemon = pokemon
                self.pokesList[cell.cellIndex].fetched = true
                self.pokesList[cell.cellIndex].image = "\(pokemonImageUrl)\(id).png"
                let pokeTypes = pokemon.types! // maximum 2 pokemon types
                
                DispatchQueue.main.async {
                    if pokeTypes.count > 1 {

                        cell.pokeType1.image = UIImage(named: (pokeTypes[0].type?.name!.capitalized)!)
                        cell.pokeType2.image = UIImage(named: (pokeTypes[1].type?.name!.capitalized)!)
                        
                    } else {
                        cell.pokeType2.image = UIImage(named: (pokeTypes[0].type?.name!.capitalized)!)
                    }
                }
                
                break
            case .failure(let error) :
                print("Fetch Poke Error = \(error.localizedDescription)")
                break
            }
            
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pokesList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tbCell()
        
        cell.cellIndex = indexPath.row
        
        pokesList[indexPath.row].image = "\(pokemonImageUrl)\(cell.cellIndex + 1).png"
        
        let rowObject = pokesList[indexPath.row]
        
        cell.pokeNameLabel.text = rowObject.name.capitalized
        cell.pokeNumberLabel.text = getPokeNum(integer: cell.cellIndex + 1)
        cell.selectionStyle = .none
        
        print("here - \(indexPath.row)")
        
        fetchPokemonImage(object: rowObject, cell: cell)
        
        if rowObject.fetched == false {
            print("send API call")
            loadCellWithData(cell: cell)
        }else{
            print("get cached data")
            let pokeTypes = rowObject.pokemon!.types! // maximum 2 pokemon types
            
            if pokeTypes.count > 1 {

                cell.pokeType1.image = UIImage(named: (pokeTypes[0].type?.name!.capitalized)!)
                cell.pokeType2.image = UIImage(named: (pokeTypes[1].type?.name!.capitalized)!)
                
            } else {
                cell.pokeType2.image = UIImage(named: (pokeTypes[0].type?.name!.capitalized)!)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! tbCell
        
        let rowObject = pokesList[indexPath.row]
        
        let alert = UIAlertController(title: "\n\nHello, \(rowObject.name.capitalized)", message: "This pokemon has \(rowObject.pokemon!.moves!.count) moves & \(rowObject.pokemon!.abilities!.count) abilities.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Nice !", style: .default, handler: nil))
        
        let imageView = UIImageView(frame: CGRect(x: 270/2 - 20, y: 15, width: 40, height: 40))
        imageView.image = cell.pokeImage!.image
        alert.view.addSubview(imageView)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIButton(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        
        view.setTitle("Pokemon List Example", for: .normal)
        view.backgroundColor = .systemRed
        view.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(50)
    }
    
    let defaults = UserDefaults.standard
    
    func fetchPokemonImage(object: pokeObject, cell: tbCell) {
        
        if defaults.object(forKey: object.image!) != nil {
            print("using saved pokemon image")
            cell.pokeImage.image = UIImage(data: UserDefaults.standard.object(forKey: object.image!) as! Data)
        }else{
            let url = URL(string: object.image!)!
            
            URLSession.shared.dataTask(with: url) { [weak self] (data, _, _) in
                if let data = data {
                    
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(data, forKey: object.image!)
                        cell.pokeImage.image = UIImage(data: data)
                    }
                    
                }
            }.resume()
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(60)
    }
    
    func loadCellWithData(cell: tbCell) {
        
        if cell.pokeNameLabel.text == "" {
            cell.pokeImage.backgroundColor = .black
            cell.pokeNameLabel.text = "something wrong w/ pokemon API"
            return
        }
        
        cell.pokeImage.backgroundColor = .white
        
        fetchPoke(id: "\(cell.cellIndex + 1)", for: cell)
        
    }
    
    func getPokeNum(integer: Int) -> String {
        
        if integer > 99 {
            return "#\(integer)"
        }else if integer > 9 {
            return "#0\(integer)"
        }
        
        return "#00\(integer)"
        
    }
    
}

class tbCell : UITableViewCell {
    
    var pokeImage : UIImageView!
    var pokeNameLabel : UILabel!
    var pokeNumberLabel : UILabel!
    
    var pokeType1 : UIImageView!
    var pokeType2 : UIImageView!
    
    var cellIndex : Int!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
        pokeImage = UIImageView(frame: CGRect(x: 10, y: 10, width: 40, height: 40))
        self.contentView.addSubview(pokeImage)
        
        pokeImage.contentMode = .scaleAspectFit
        
        pokeNameLabel = UILabel(frame: CGRect(x: 55, y: 10, width: 100, height: 20))
        self.contentView.addSubview(pokeNameLabel)
        
        pokeNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        
        pokeNumberLabel = UILabel(frame: CGRect(x: 55, y: 30, width: 100, height: 20))
        self.contentView.addSubview(pokeNumberLabel)
        
        pokeNumberLabel.textColor = .lightGray
        pokeNumberLabel.font = UIFont.systemFont(ofSize: 14)
        
        pokeType2 = UIImageView(frame: CGRect(x: UIScreen.main.bounds.width - 45, y: 15, width: 30, height: 30))
        self.contentView.addSubview(pokeType2)
        
        pokeType1 = UIImageView(frame: CGRect(x: UIScreen.main.bounds.width - 90, y: 15, width: 30, height: 30))
        self.contentView.addSubview(pokeType1)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

let pokemonImageUrl = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/"
let fetchFirst50 = "https://pokeapi.co/api/v2/pokemon/?limit=50&offset=0"
var fetchNext50 = "https://pokeapi.co/api/v2/pokemon/?limit=50&offset=0"
