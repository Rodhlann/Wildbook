QUnit.module('Co-Occurrence Graph Interface');

let cg;
QUnit.begin(() => {
    let individualId = "mock"
    cg = new OccurrenceGraph(individualId);
});

QUnit.module('calculateDist()', () => {
    QUnit.test('Valid distances', t => {
	let node1Loc = {
	    "lon": 10,
	    "lat": 0
	}
	let node2Loc = {
	    "lon": 0,
	    "lat": 0
	}
	t.equal(cg.calculateDist(node1Loc, node2Loc), 10)
    });

    QUnit.test('Invalid distances', t => {
	t.equal(cg.calculateDist(null, 10), -1)
    });
});

QUnit.module('calculateTime()', () => {
    QUnit.test('Valid times', t => {
	t.equal(cg.calculateTime(10, 0), 10)
    });

    QUnit.test('Invalid times', t => {
	t.equal(cg.calculateTime(10, null), -1)
    });
});

let linearInterpEventHooks = {
    'before': () => cg.id = "a",
    'after': () => cg.id = null
}
QUnit.module('linearInterp()', linearInterpEventHooks, () => {
    QUnit.test('Valid x-axis interpolation', t => {
	let link = {
	    'source': {
		'data': {
		    'individualID': "a"
		},
		'x': 10
	    },
	    'target': {
		'x': 0
	    }
	};
	t.equal(cg.linearInterp(link, "x"), 4);
    });

    QUnit.test('Valid y-axis interpolation', t => {
	let link = {
	    'source': {
		'data': {
		    'individualID': "a"
		},
		'y': 0
	    },
	    'target': {
		'y': 10
	    }
	};
	t.equal(cg.linearInterp(link, "y"), 6);
    });
    
    QUnit.test('Invalid link data', t => {
	t.equal(cg.linearInterp(null, "z"), -1)
    });
});
