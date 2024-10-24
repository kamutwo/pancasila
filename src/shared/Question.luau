local module = {}

local questions = {
	{
		question = [[1 + 1]],
		options = {
			[[1]],
			[[2]],
			[[3]],
			[[4]],
			[[5]]
		},
		answerIdx = 2
	},
	{
		question = [[2 + 1]],
		options = {
			[[1]],
			[[2]],
			[[3]],
			[[4]],
			[[5]]
		},
		answerIdx = 3
	},
	{
		question = [[69 * 0]],
		options = {
			[[0]],
			[[1]],
			[[2]],
			[[3]],
			[[4]]
		},
		answerIdx = 1
	},
	{
		question = [[ Pada sidang pertama PPKI yang dilaksanakan pada 18 Agustus 1945, terjadi pembahasan penting mengenai kalimat dalam Piagam Jakarta yang berbunyi "Ketoehanan, dengan kewajiban mendjalankan sjariat Islam bagi pemeloek-pemeloeknja". Apa alasan utama perubahan kalimat ini, dan apa hasil kesepakatannya ..... ]],
		options = {
			[[ Alasan perubahan kalimat ini karena adanya tekanan dari Sekutu; hasil kesepakatannya adalah mengubahnya menjadi Ketuhanan Yang Maha Esa untuk menjaga persatuan bangsa ]], 
			[[ Alasan perubahan kalimat ini karena keberatan dari golongan militer; hasil kesepakatannya adalah mengubahnya menjadi Ketuhanan Yang Maha Esa untuk menghindari konflik internal ]], 
			[[ Alasan perubahan kalimat ini karena keberatan dari para pemeluk agama selain Islam di indonesia bagian timur yang merasa didiskriminasi; hasil kesepakatannya adalah mengubahnya menjadi Ketuhanan Yang Maha Esa ]], 
			[[ Alasan perubahan kalimat ini karena tekanan dari Jepang yang ingin memepertahankan kekuasaan mereka; hasil kesepakatannya adalah tetap mempertahankan kalimat asli, namun menambahkan penjelasan ]], 
			[[ Alasan perubahan kaliamat ini karena permintaan dari tokoh-tokoh Islam; hasil kesepakatannya adalah mengubahnya menjadi Ketuhanan Yang Maha Esa untuk menjaga keberagaman ]]}
		,
		answerIdx = 1
	}
}

function module.randQuestion(prevQuestions: {string})
	local question
	repeat
		local randIdx = math.random(1, #questions)
		question = questions[randIdx]

		task.wait()
	until not table.find(prevQuestions, question.question)
	return question
end

return module
