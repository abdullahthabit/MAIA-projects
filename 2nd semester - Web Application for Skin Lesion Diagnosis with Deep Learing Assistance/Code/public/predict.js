
let model;
(async function() {
    $(".progress-bar").show();
    model = undefined;
    model = await tf.loadModel(`http://localhost:8080/tfjs-models/MobileNet/model.json`);
    $(".progress-bar").hide();
})();

$("#case-selector").change(function () {
    $("#prediction-list").empty();
});

$("#predict-button").click(async function () {
    let image = $("#myskin").get(0);
    console.log('image:', image)
    let tensor = preprocessImage(image);
    console.log('Image tensor:', tensor)
    let predictions = await model.predict(tensor).data();
    let top3 = Array.from(predictions)
        .map(function (p, i) {
            return {
                probability: p,
                className: SKIN_LESION_CLASSES[i]
            };
        }).sort(function (a, b) {
            return b.probability - a.probability;
        }).slice(0, 3);

    $("#prediction-list").empty();
    top3.forEach(function (p,indx) {
        $("#prediction-list").append(`<li>${p.className}: ${p.probability.toFixed(6)}</li>`);
        var resultno = "result" + indx;
        var predno = "pred" + indx;
        var classnn = p.className; 
        var pred1 = p.probability.toFixed(6); 
        var mypred = classnn + ":" + pred1;
        $("ul.case_info").append('<input name='+ resultno+' id='+ resultno +' value ='+ classnn +' type = "hidden" role="option" size="2" readonly><input name='+ predno+' id='+ predno +' value ='+ pred1 +'  role="option" type = "hidden" size="8" readonly></br>'); 
    });
});

function preprocessImage(image) {
    let tensor = tf.fromPixels(image)
        .resizeNearestNeighbor([224, 224])
        .toFloat();
    return tensor.expandDims();
}

