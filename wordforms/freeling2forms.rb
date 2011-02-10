FORMS_DATA = {}
count = 0
$KCODE = 'u'

File.open('ES.data.txt') do |f|
  f.each do |line|
    count += 1
    data = line.split(/\s+/)
    (FORMS_DATA[data[1]] ||= []) << data[0]
    # break if count == 100
  end
end

FORMS_DATA.sort.each { |pair|
  k, v = pair
  forms = v.uniq
  forms.delete(k) # no point of having the base form to be in the list of forms
  if forms.size == 0
    $stderr.puts "Empty list of wordforms for the word: #{k}"
    next
  end
  puts "#{k}: #{forms.join(', ')}"
}
