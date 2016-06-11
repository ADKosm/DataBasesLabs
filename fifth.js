db.Movie.find({"_id" : "\"12 oz. Mouse\" (2005)"}).pretty();  // выбрать сериал или фильм

db.Movie.find().forEach(function(data) { // исправить везде строки на числа
    db.Movie.update({
        "_id": data._id
    }, {
        "$set": {
            "RunningTime": parseInt(data.RunningTime)
        }
    });
});

db.Movie.find({"Rating.Rating": {$exists: true}, "Rating.RatingVotes": {$exists: true}}).forEach(function(data) { // опять же исправить везде строки на числа  (но теперь только там, где существуют соответствующие поля)
    db.Movie.update({
        "_id": data._id
    }, {
        "$set": {
            "Rating.Rating": parseFloat(data.Rating.Rating),
            "Rating.RatingVotes": parseInt(data.Rating.RatingVotes)
        }
    });
});

db.Movie.find().forEach(function(data){ // добовляет каждому файлу поле с длинной названия
    db.Movie.update({"_id": data._id},{
        "$set": {
            "NameLength": data._id.length
        }
    });
});

db.Movie.find({'SeriesType': 'S', 'ReleaseYear': {$exists: true}}).forEach(function(data){ // попроавляем год выпуска, чтобы он стал числом (нужно для следующих запросов)
    db.Movie.update({"_id": data._id}, {
        "$set": {
            'ReleaseYear': parseInt(data.ReleaseYear)
        }
    });
});

db.Movie.aggregate([ // количество фильмов в каждый год в период с 2000 по 2010
    {$match: { "ReleaseYear": {$exists: true, $gte: 2000, $lte: 2010} }},
    { $group: { _id: "$ReleaseYear", total: {$sum: 1} }}
]);

var countryKeywords = function(country) { // наиболее популярные ключевые слова по стране
    return db.Movie.aggregate([
        { $unwind: '$Countries' },
        { $match: { Countries: country } },
        { $unwind: '$Keywords' },
        { $group: {_id: "$Keywords", total: {$sum: 1}} },
        { $sort: {total: -1}},
        { $limit: 10 }
    ]);
};

var movieRaiting = function(movieName) { // формула рейгинта фильма. В данном примере срденее геометрическое между Rating и RatingVotes деленное на количество фильмов, снятое в этой же стране :)
    var countryCount = function (country){
        return db.Movie.find({Countries: country}).count();
    };

    var movie = db.Movie.find({_id: movieName}).toArray();
    var countryNumber = countryCount(movie[0].Countries[0]);

    return Math.sqrt(movie[0].Rating.Rating * movie[0].Rating.RatingVotes) / countryNumber;
};
